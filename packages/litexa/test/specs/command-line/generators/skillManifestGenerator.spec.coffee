
###

 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved.
 * These materials are licensed as "Restricted Program Materials" under the Program Materials
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service.
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html.
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized
 * terms not defined in this file have the meanings given to them in the Agreement.
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 
###


{fake, match, spy} = require('sinon')

chai = require('chai')
chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
{assert, expect} = chai

fs = require 'fs'
SkillManifestGenerator = require('@src/command-line/generators/skillManifestGenerator')

describe 'SkillManifestGenerator', ->
  describe '#description', ->
    it 'has a class property to describe itself', ->
      assert(SkillManifestGenerator.hasOwnProperty('description'), 'has a property description')
      expect(SkillManifestGenerator.description).to.equal('skill manifest')

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
    options = undefined

    beforeEach ->
      options = {
        root: '.',
        configLanguage: 'javascript',
        projectConfig: {
          name: 'mock'
        }
      }
      loggerInterface = {
        log: () -> undefined
      }
      inquirer =  {
        prompt: fake.returns(Promise.resolve({storeTitleName: options.projectConfig.name}))
      }

    afterEach ->
      for extension in ['coffee', 'js', 'json']
        filename = "skill.#{extension}"
        if fs.existsSync filename
          fs.unlinkSync filename

    it 'returns a promise', ->
      skillManifestGenerator = new SkillManifestGenerator({
        options,
        logger: loggerInterface,
        inputHandler: inquirer
      })

      assert.typeOf(skillManifestGenerator.generate(), 'promise', 'it returns a promise')

    it "throws an error for extensions that aren't found", ->
      options.configLanguage = 'unknownFormat'

      skillManifestGenerator = new SkillManifestGenerator({
        options,
        logger: loggerInterface,
        inputHandler: inquirer
      })

      testFn = ->
        await skillManifestGenerator.generate()

      assert.isRejected(testFn(), 'extension not found', 'throws an error')

    it 'skips if the file already exists', ->
      fs.writeFileSync 'skill.js', 'content', 'utf8'
      logSpy = spy(loggerInterface, 'log')

      skillManifestGenerator = new SkillManifestGenerator({
        options,
        logger: loggerInterface,
        inputHandler: inquirer
      })

      await skillManifestGenerator.generate()

      data = fs.readFileSync 'skill.js', 'utf8'
      assert(logSpy.calledOnceWith(match('existing skill.js found -> skipping creation')),
        'informed user skipping generator')
      assert(logSpy.neverCalledWith(match('creating')),
        "doesn't misinform the user")
      assert(data == 'content', 'did not override file')

    it 'writes the manifest in JavaScript', ->
      logSpy = spy(loggerInterface, 'log')

      skillManifestGenerator = new SkillManifestGenerator({
        options,
        logger: loggerInterface,
        inputHandler: inquirer
      })

      await skillManifestGenerator.generate()

      assert(logSpy.neverCalledWith(match('existing skill.js found -> skipping creation')),
        "doesn't misinform the user")
      assert(logSpy.calledWith(match('creating skill.js -> contains skill manifest and should
        be version controlled')),
        "informs it's writing the file and prompts user to version control it")
      assert(fs.existsSync('skill.js'), 'wrote the actual file')

    it 'writes the manifest in coffee', ->
      options.configLanguage = 'coffee'
      logSpy = spy(loggerInterface, 'log')

      skillManifestGenerator = new SkillManifestGenerator({
        options,
        logger: loggerInterface,
        inputHandler: inquirer
      })

      await skillManifestGenerator.generate()

      assert(logSpy.neverCalledWith(match('existing skill.coffee found -> skipping creation')),
        "doesn't misinform the user")
      assert(logSpy.calledWith(match('creating skill.coffee -> contains skill manifest and should
        be version controlled')),
        "informs it's writing the file and prompts user to version control it")
      assert(fs.existsSync('skill.coffee'), 'wrote the actual file')

    it 'writes the manifest in json', ->
      options.configLanguage = 'json'
      logSpy = spy(loggerInterface, 'log')

      skillManifestGenerator = new SkillManifestGenerator({
        options,
        logger: loggerInterface,
        inputHandler: inquirer
      })

      await skillManifestGenerator.generate()

      assert(logSpy.neverCalledWith(match('existing skill.json found -> skipping creation')),
        "doesn't misinform the user")
      assert(logSpy.calledWith(match('creating skill.json -> contains skill manifest and should
        be version controlled')),
        "informs it's writing the file and prompts user to version control it")
      assert(fs.existsSync('skill.json'), 'wrote the actual file')

    it 'prompts the user for input with a default store title', ->
      options.projectConfig.name = 'sample'

      skillManifestGenerator = new SkillManifestGenerator({
        options,
        logger: loggerInterface,
        inputHandler: inquirer
      })

      await skillManifestGenerator.generate()

      assert(
        inquirer.prompt.calledWith(
          match({message: 'What would you like the skill store title of the project to be?
            (default: "sample")'})
        ), 'prompted the user with default store title'
      )


    it 'prompts the user for input without a default store title', ->
      options.projectConfig.name = 'AlexaEchoSkill'
      skillManifestGenerator = new SkillManifestGenerator({
        options,
        logger: loggerInterface,
        inputHandler: inquirer
      })

      await skillManifestGenerator.generate()

      assert(
        inquirer.prompt.calledWith(
          match({message: 'What would you like the skill store title of the project to be?' })
        ), 'prompted the user without default store title'
      )
