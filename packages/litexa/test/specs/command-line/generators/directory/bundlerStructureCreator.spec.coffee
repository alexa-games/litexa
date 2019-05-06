
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


{assert} = require('chai')
{match,spy,stub} = require('sinon')

path = require 'path'

BundlerStructureCreator = require('@src/command-line/generators/directory/bundlerStructureCreator')

describe 'BundlerStructureCreator', ->
  rootPath = '.'
  loggerInterface = undefined
  templateFilesHandler = undefined
  beforeEach ->
    loggerInterface = {
      log: () -> undefined
    }
    templateFilesHandler = {
      syncDir: () -> undefined
    }

  describe '#create', ->
    it 'creates the appropriate directory structure', ->
      ensureDirExistsStub = stub(BundlerStructureCreator.prototype, 'ensureDirExists').callsFake(-> true)
      bundlerStructureCreator = new BundlerStructureCreator({
        logger: loggerInterface,
        rootPath
      })

      bundlerStructureCreator.create()

      assert(ensureDirExistsStub.calledWith('litexa'), 'created the litexa directory')
      assert(ensureDirExistsStub.calledWith(path.join 'lib', 'services'), 'created the lib services directory')
      assert(ensureDirExistsStub.calledWith(path.join 'lib', 'components'), 'created the lib components directory')


  describe '#sync', ->
    it 'targets the correct destination directory', ->
      syncDirSpy = spy(templateFilesHandler, 'syncDir')

      bundlerStructureCreator = new BundlerStructureCreator({
        logger: loggerInterface,
        sourceLanguage: 'javascript'
        bundlingStrategy: 'none'
        rootPath
        templateFilesHandler
      })

      bundlerStructureCreator.sync()

      assert(syncDirSpy.calledWith(match({destination: '.'})), 'targets the top level directory')
      assert(syncDirSpy.calledWith(match({destination: 'litexa'})), 'targets the litexa directory')
      assert(syncDirSpy.calledWith(match({destination: 'lib'})), 'targets the lib directory')
      assert(syncDirSpy.calledWith(match({destination: path.join 'lib', 'services'})), 'targets the lib services directory')
      assert(syncDirSpy.calledWith(match({destination: path.join 'lib', 'components'})), 'targets the lib components directory')
      assert(syncDirSpy.calledWith(match({destination: path.join 'test', 'services'})), 'targets the test services directory')
      assert(syncDirSpy.calledWith(match({destination: path.join 'test', 'components'})), 'targets the test components directory')


    it 'targets the correct directories for webpack bundling with JavaScript', ->
      syncDirSpy = spy(templateFilesHandler, 'syncDir')
      bundlerStructureCreator = new BundlerStructureCreator({
        logger: loggerInterface
        sourceLanguage: 'javascript'
        bundlingStrategy: 'webpack'
        rootPath
        templateFilesHandler
      })

      bundlerStructureCreator.sync()

      expectedDirsLitexa = [
        path.join 'common', 'litexa'
      ]
      expectedDirsJavaScript = [
        path.join 'common', 'javascript'
        path.join 'bundled', 'javascript'
      ]

      assert(syncDirSpy.calledWith(match({sourcePaths: expectedDirsLitexa})),
        'reads from the correct directories for the litexa files')
      assert(syncDirSpy.calledWith(match({sourcePaths: expectedDirsJavaScript})),
        'reads from the correct directories for the JavaScript files')

    it 'targets the correct directories for webpack bundling with TypeScript', ->
      syncDirSpy = spy(templateFilesHandler, 'syncDir')
      bundlerStructureCreator = new BundlerStructureCreator({
        logger: loggerInterface,
        sourceLanguage: 'typescript'
        bundlingStrategy: 'webpack'
        rootPath
        templateFilesHandler
      })

      bundlerStructureCreator.sync()

      expectedDirsLitexa = [
        path.join 'common', 'litexa'
      ]
      expectedDirsTypeScript = [
        path.join 'common', 'typescript', 'config'
        path.join 'bundled', 'typescript', 'config'
        path.join 'common', 'typescript', 'source'
        path.join 'bundled', 'typescript', 'source'
      ]

      assert(syncDirSpy.calledWith(match({sourcePaths: expectedDirsLitexa})),
        'reads from the correct directories for the litexa files')
      assert(syncDirSpy.calledWith(match({sourcePaths: expectedDirsTypeScript})),
        'reads from the correct directories for the TypeScript files')

    it 'targets the correct directories for webpack bundling with CoffeeScript', ->
      syncDirSpy = spy(templateFilesHandler, 'syncDir')
      bundlerStructureCreator = new BundlerStructureCreator({
        logger: loggerInterface,
        sourceLanguage: 'coffee'
        bundlingStrategy: 'webpack'
        rootPath
        templateFilesHandler
      })

      bundlerStructureCreator.sync()

      expectedDirsLitexa = [
        path.join 'common', 'litexa'
      ]
      expectedDirsCoffeeScript = [
        path.join 'common', 'coffee'
        path.join 'bundled', 'coffee'
      ]

      assert(syncDirSpy.calledWith(match({sourcePaths: expectedDirsLitexa})),
        'reads from the correct directories for the litexa files')
      assert(syncDirSpy.calledWith(match({sourcePaths: expectedDirsCoffeeScript})),
        'reads from the correct directories for the CoffeeScript files')
