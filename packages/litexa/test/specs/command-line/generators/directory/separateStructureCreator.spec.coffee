###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

{assert} = require('chai')
{match,spy,stub} = require('sinon')

path = require 'path'

SeparateStructureCreator = require('@src/command-line/generators/directory/separateStructureCreator')

describe 'SeparateStructureCreator', ->
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
      ensureDirExistsStub = stub(SeparateStructureCreator.prototype, 'ensureDirExists').callsFake(-> true)
      separateStructureCreator = new SeparateStructureCreator({
        logger: loggerInterface,
        rootPath
      })

      separateStructureCreator.create()

      assert(ensureDirExistsStub.calledWith('litexa'), 'created the litexa directory')
      assert(ensureDirExistsStub.calledWith('lib'), 'created the lib directory')

  describe '#sync', ->
    it 'targets the correct destination directory', ->
      syncDirSpy = spy(templateFilesHandler, 'syncDir')

      separateStructureCreator = new SeparateStructureCreator({
        logger: loggerInterface
        sourceLanguage: 'javascript'
        bundlingStrategy: 'none'
        rootPath
        templateFilesHandler
      })

      separateStructureCreator.sync()

      assert(syncDirSpy.calledWith(match({destination: 'litexa'})), 'targets the litexa directory')
      assert(syncDirSpy.calledWith(match({destination: 'lib'})), 'targets the lib directory')


    it 'targets the correct directories for npm-link bundling with JavaScript', ->
      syncDirSpy = spy(templateFilesHandler, 'syncDir')
      separateStructureCreator = new SeparateStructureCreator({
        logger: loggerInterface
        sourceLanguage: 'javascript'
        bundlingStrategy: 'npm-link'
        rootPath
        templateFilesHandler
      })

      separateStructureCreator.sync()

      expectedDirsLitexa = [
        path.join 'common', 'litexa'
        path.join 'separate', 'litexa'
      ]
      expectedDirsJavaScript = [
        path.join 'common', 'javascript'
        path.join 'separate', 'javascript'
      ]

      assert(syncDirSpy.calledWith(match({ sourcePaths: expectedDirsLitexa })),
        'reads from the correct directories for the litexa files')
      assert(syncDirSpy.calledWith(match({ sourcePaths: expectedDirsJavaScript })),
        'reads from the correct directories for the javascript files')

    it 'targets the correct directories for npm-link bundling with TypeScript', ->
      syncDirSpy = spy(templateFilesHandler, 'syncDir')
      separateStructureCreator = new SeparateStructureCreator({
        logger: loggerInterface,
        sourceLanguage: 'typescript'
        bundlingStrategy: 'npm-link'
        rootPath
        templateFilesHandler
      })

      separateStructureCreator.sync()

      expectedDirsLitexa = [
        path.join 'common', 'litexa'
        path.join 'separate', 'litexa'
      ]
      expectedDirsTypeScript = [
        path.join 'common', 'typescript', 'source'
        path.join 'separate', 'typescript'
      ]

      assert(syncDirSpy.calledWith(match({ sourcePaths: expectedDirsLitexa })),
        'reads from the correct directories for the litexa files')
      assert(syncDirSpy.calledWith(match({ sourcePaths: expectedDirsTypeScript })),
        'reads from the correct directories for the typescript files')

    it 'targets the correct directories for npm-link bundling with CoffeeScript', ->
      syncDirSpy = spy(templateFilesHandler, 'syncDir')
      separateStructureCreator = new SeparateStructureCreator({
        logger: loggerInterface,
        sourceLanguage: 'coffee'
        bundlingStrategy: 'npm-link'
        rootPath
        templateFilesHandler
      })

      separateStructureCreator.sync()

      expectedDirsLitexa = [
        path.join 'common', 'litexa'
        path.join 'separate', 'litexa'
      ]
      expectedDirsCoffeeScript = [
        path.join 'common', 'coffee'
        path.join 'separate', 'coffee'
      ]

      assert(syncDirSpy.calledWith(match({ sourcePaths: expectedDirsLitexa })),
        'reads from the correct directories for the litexa files')
      assert(syncDirSpy.calledWith(match({ sourcePaths: expectedDirsCoffeeScript })),
        'reads from the correct directories for the coffee files')
