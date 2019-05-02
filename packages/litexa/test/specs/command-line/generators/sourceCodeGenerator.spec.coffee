{assert, expect} = require('chai')
{match, spy, stub} = require('sinon')

path = require 'path'
fs = require 'fs'
rimraf = require 'rimraf'
mkdirp = require 'mkdirp'

SourceCodeGenerator = require('@src/command-line/generators/sourceCodeGenerator')
DirectoryCreator = require('@src/command-line/generators/directoryCreator')

Test = require('@test/helpers')

describe 'SourceCodeGenerator', ->
  describe '#description', ->
    it 'has a class property to describe itself', ->
      assert(SourceCodeGenerator.hasOwnProperty('description'), 'has a property description')
      expect(SourceCodeGenerator.description).to.equal('litexa entry point')

  describe 'generate', ->
    options = undefined
    loggerInterface = undefined
    mockLanguage = undefined

    beforeEach ->
      options = {
        root: '.'
        configLanguage: 'javascript'
        sourceLanguage: 'javascript'
        bundlingStrategy: 'none'
        projectConfig: {
          name: 'test'
        }
      }
      loggerInterface = {
        log: () -> undefined
      }
      mockLanguage = {
        code: {
          files: ['main.litexa']
        }
      }

    afterEach ->
      dir = 'litexa'
      if fs.existsSync(dir)
        rimraf.sync(dir)

    it 'returns a promise', ->
      hasCodeStub = stub(SourceCodeGenerator.prototype, '_hasLitexaCode').returns(true)
      sourceCodeGenerator = new SourceCodeGenerator({
        options
        logger: loggerInterface
        projectInfoClass: Test.MockProjectInfoInterface
        templateFilesHandlerClass: Test.MockFileHandlerInterface
        directoryCreatorClass: Test.MockDirectoryCreatorInterface
      })
      assert.typeOf(sourceCodeGenerator.generate(), 'promise', 'it returns a promise')
      hasCodeStub.restore()

    it 'creates the directory structure', ->
      hasCodeStub = stub(SourceCodeGenerator.prototype, '_hasLitexaCode').returns(true)
      createSpy = spy(Test.MockDirectoryCreator.prototype, 'create')

      sourceCodeGenerator = new SourceCodeGenerator({
        options
        logger: loggerInterface
        projectInfoClass: Test.MockProjectInfoInterface
        templateFilesHandlerClass: Test.MockFileHandlerInterface
        directoryCreatorClass: Test.MockDirectoryCreatorInterface
      })
      sourceCodeGenerator.generate()

      assert(createSpy.calledOnce, 'created the directory structure')
      hasCodeStub.restore()

    it 'synchronizes the directory if no litexa code exists', ->
      hasCodeStub = stub(SourceCodeGenerator.prototype, '_hasLitexaCode').returns(false)
      logSpy = spy(loggerInterface, 'log')
      syncSpy = spy(Test.MockDirectoryCreator.prototype, 'sync')

      sourceCodeGenerator = new SourceCodeGenerator({
        options
        logger: loggerInterface
        projectInfoClass: Test.MockProjectInfoInterface
        templateFilesHandlerClass: Test.MockFileHandlerInterface
        directoryCreatorClass: Test.MockDirectoryCreatorInterface
      })
      sourceCodeGenerator.generate()

      assert(syncSpy.calledOnce, 'created the directory structure')
      assert(logSpy.calledWith(match("no code files found in litexa -> creating them")),
        'informed the user it was going to create the files')
      hasCodeStub.restore()
