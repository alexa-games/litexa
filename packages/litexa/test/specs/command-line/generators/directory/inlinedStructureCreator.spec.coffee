###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

{assert} = require('chai')
{match,spy,stub} = require('sinon')

path = require 'path'

InlinedStructureCreator = require('@src/command-line/generators/directory/inlinedStructureCreator')

describe 'InlinedStructureCreator', ->
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
      ensureDirExistsStub = stub(InlinedStructureCreator.prototype, 'ensureDirExists').callsFake(-> true)
      inlinedStructureCreator = new InlinedStructureCreator({
        logger: loggerInterface,
        rootPath
      })

      inlinedStructureCreator.create()

      assert(ensureDirExistsStub.calledWith('litexa'), 'created the litexa directory')

  describe '#sync', ->
    it 'targets the correct destination directory', ->
      syncDirSpy = spy(templateFilesHandler, 'syncDir')

      inlinedStructureCreator = new InlinedStructureCreator({
        logger: loggerInterface
        sourceLanguage: 'javascript'
        bundlingStrategy: 'none'
        rootPath
        templateFilesHandler
      })

      inlinedStructureCreator.sync()

      assert(syncDirSpy.calledWith(match({destination: 'litexa'})), 'targets the litexa directory')


    it 'targets the correct directories for none bundling with JavaScript', ->
      syncDirSpy = spy(templateFilesHandler, 'syncDir')
      inlinedStructureCreator = new InlinedStructureCreator({
        logger: loggerInterface
        sourceLanguage: 'javascript'
        bundlingStrategy: 'none'
        rootPath
        templateFilesHandler
      })

      inlinedStructureCreator.sync()

      expectedDirs = [
        path.join 'common', 'litexa'
        path.join 'common', 'javascript'
        path.join 'inlined', 'javascript'
      ]

      assert(syncDirSpy.calledWith(match({sourcePaths: expectedDirs})), 'reads from the correct directories')

    it 'targets the correct directories for none bundling with TypeScript', ->
      syncDirSpy = spy(templateFilesHandler, 'syncDir')
      inlinedStructureCreator = new InlinedStructureCreator({
        logger: loggerInterface,
        sourceLanguage: 'typescript'
        bundlingStrategy: 'none'
        rootPath
        templateFilesHandler
      })

      inlinedStructureCreator.sync()

      expectedDirs = [
        path.join 'common', 'litexa'
        path.join 'common', 'typescript'
        path.join 'inlined', 'typescript'
      ]

      assert(syncDirSpy.calledWith(match({sourcePaths: expectedDirs})), 'reads from the correct directories')

    it 'targets the correct directories for none bundling with CoffeeScript', ->
      syncDirSpy = spy(templateFilesHandler, 'syncDir')
      inlinedStructureCreator = new InlinedStructureCreator({
        logger: loggerInterface,
        sourceLanguage: 'coffee'
        bundlingStrategy: 'none'
        rootPath
        templateFilesHandler
      })

      inlinedStructureCreator.sync()

      expectedDirs = [
        path.join 'common', 'litexa'
        path.join 'common', 'coffee'
        path.join 'inlined', 'coffee'
      ]

      assert(syncDirSpy.calledWith(match({sourcePaths: expectedDirs})), 'reads from the correct directories')
