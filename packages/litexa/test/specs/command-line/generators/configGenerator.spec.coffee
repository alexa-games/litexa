{fake, match, mock, spy, stub} = require('sinon')

chai = require('chai')
chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
{assert, expect} = chai

ConfigGenerator = require('@src/command-line/generators/configGenerator')

describe 'ConfigGenerator', ->
  describe '#description', ->
    it 'has a class property to describe itself', ->
      assert(ConfigGenerator.hasOwnProperty('description'), 'has a property description')
      expect(ConfigGenerator.description).to.equal('config file')

  describe '#generate', ->
    mockConfig = {
      name: 'mock',
      deployments: {
        development: {
          module: '@litexa/deploy-aws',
          S3BucketName: 'mock-litexa-assets',
          askProfile: 'mock'
        }
      },
      plugins: {}
    }

    loggerInterface = undefined
    inquirer = undefined
    configInterface = undefined
    options = undefined
    name = 'projectName'

    beforeEach ->
      options = {
        root: '.',
        configLanguage: 'javascript'
        bundlingStrategy: 'none'
      }
      loggerInterface = {
        log: () -> undefined
      }
      inquirer = {
        prompt: fake.returns(Promise.resolve({projectName: name}))
      }
      configInterface = {
        writeDefault: () -> undefined,
        identifyConfigFileFromPath: () -> undefined,
        loadConfig: () -> undefined
      }

    it 'returns a promise', ->
      stub(configInterface, 'identifyConfigFileFromPath').throws()
      stub(configInterface, 'writeDefault').callsFake(-> 'mockFile')
      stub(configInterface, 'loadConfig').callsFake(-> mockConfig)

      configGenerator = new ConfigGenerator({
        options,
        config: configInterface,
        logger: loggerInterface,
        inputHandler: inquirer
      })

      assert.typeOf(configGenerator.generate(), 'promise', 'it returns a promise')

    it 'mutates options as a direct public side-effect', ->
      stub(configInterface, 'identifyConfigFileFromPath').callsFake(-> './mockFile')
      stub(configInterface, 'writeDefault').callsFake(-> 'mockFile')
      stub(configInterface, 'loadConfig').callsFake(-> mockConfig)

      configGenerator = new ConfigGenerator({
        options,
        config: configInterface,
        logger: loggerInterface,
        inputHandler: inquirer
      })

      await configGenerator.generate()

      assert(options.hasOwnProperty('projectConfig'),
        'modified the options to include a project config')
      expect(options.projectConfig).to.deep.equal(mockConfig)

    it 'finds the file and loads the configuration', ->
      identifyStub = stub(configInterface, 'identifyConfigFileFromPath').callsFake(-> './mockFile')
      writeStub = stub(configInterface, 'writeDefault').callsFake(-> 'mockFile')
      loadStub = stub(configInterface, 'loadConfig').callsFake(-> mockConfig)
      logSpy = spy(loggerInterface, 'log')

      configGenerator = new ConfigGenerator({
        options,
        config: configInterface,
        logger: loggerInterface,
        inputHandler: inquirer
      })

      await configGenerator.generate()

      assert(identifyStub.calledOnceWith(options.root), 'looked for file in the appropriate place')
      assert(logSpy.calledOnceWith(match('found -> skipping creation')),
        'informed user of appropriate action')
      assert(loadStub.calledOnceWith(options.root), 'loaded the config file')
      assert(writeStub.notCalled, 'did not write anything to disk')

    it 'does not find the file, gets user input, and creates one', ->
      identifyStub = stub(configInterface, 'identifyConfigFileFromPath').throws()
      writeStub = stub(configInterface, 'writeDefault').callsFake(-> 'mockFile')
      loadStub = stub(configInterface, 'loadConfig').callsFake(-> mockConfig)
      logSpy = spy(loggerInterface, 'log')

      configGenerator = new ConfigGenerator({
        options,
        config: configInterface,
        logger: loggerInterface,
        inputHandler: inquirer
      })

      await configGenerator.generate()

      assert(identifyStub.calledOnceWith(options.root), 'looked for the file')
      assert(inquirer.prompt.called, 'prompted user for input')
      assert(logSpy.calledWith(match('creating')), "informed user it's writing the file")
      assert(writeStub.calledOnceWith(options.root, options.configLanguage, name), 'wrote to disk')
      assert(loadStub.calledOnceWith(options.root), 'loaded the config file')

    it 'throws when it finds the config file elsewhere than the root path', ->
      stub(configInterface, 'identifyConfigFileFromPath').callsFake(-> 'otherDir/mockFile')

      configGenerator = new ConfigGenerator({
        options,
        config: configInterface,
        logger: loggerInterface,
        inputHandler: inquirer
      })

      testFn = ->
        await configGenerator.generate()

      assert.isRejected(testFn(), /[cC]onfig file found in ancestor directory/, 'throws an error')

    it 'prompts the user for input with a default project name', ->
      dirName = 'sample'
      rootPathStub = stub(ConfigGenerator.prototype, '_rootPath').returns(dirName)
      stub(configInterface, 'identifyConfigFileFromPath').throws()
      stub(configInterface, 'writeDefault').callsFake(-> 'mockFile')
      stub(configInterface, 'loadConfig').callsFake(-> mockConfig)

      configGenerator = new ConfigGenerator({
        options,
        config: configInterface,
        logger: loggerInterface,
        inputHandler: inquirer
      })

      await configGenerator.generate()

      rootPathStub.restore()

      assert(
        inquirer.prompt.calledWith(
          match({message: 'What would you like to name the project? (default: "sample")'})
        ), 'prompted the user with default project name'
      )


    it 'prompts the user for input without a default project name', ->
      stub(configInterface, 'identifyConfigFileFromPath').throws()
      stub(configInterface, 'writeDefault').callsFake(-> 'mockFile')
      stub(configInterface, 'loadConfig').callsFake(-> mockConfig)

      configGenerator = new ConfigGenerator({
        options,
        config: configInterface,
        logger: loggerInterface,
        inputHandler: inquirer
      })

      await configGenerator.generate()

      assert(
        inquirer.prompt.calledWith(
          match({message: 'What would you like to name the project?'})
        ), 'prompted the user without default project name'
      )
