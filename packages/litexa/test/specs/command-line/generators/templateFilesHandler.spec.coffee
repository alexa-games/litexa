###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

{assert, expect} = require('chai')
{match, spy, stub} = require('sinon')

path = require 'path'
fs = require 'fs'
rimraf = require 'rimraf'
mkdirp = require 'mkdirp'

TemplateFilesHandler = require('@src/command-line/generators/templateFilesHandler')

describe 'TemplateFilesHandler', ->
  tmpDir = 'tmp'
  loggerInterface = undefined
  filesHandler = undefined

  beforeEach ->
    loggerInterface = {
      log: () -> undefined
    }
    filesHandler = new TemplateFilesHandler({
      logger: loggerInterface
    })
    mkdirp.sync tmpDir

  afterEach ->
    if fs.existsSync(tmpDir)
      rimraf.sync(tmpDir)

  describe '#syncDir', ->
    it "doesn't write any files if no whitelist is provided", ->
      filesHandler.syncDir({
        sourcePaths: [path.join 'common', 'litexa'],
        destination: 'tmp'
      })
      assert(!fs.existsSync(path.join 'tmp', 'main.litexa'),
        "main file did not get created because it wasn't whitelisted")
      assert(!fs.existsSync(path.join 'tmp', 'main.test.litexa'),
        "main test file did not get created because it wasn't whitelisted")

    it 'only writes the files that are whitelisted', ->
      filesHandler.syncDir({
        sourcePaths: [path.join 'common', 'litexa'],
        destination: 'tmp',
        whitelist: ['main.litexa$']
      })
      assert(fs.existsSync(path.join 'tmp', 'main.litexa'), 'main file was created')
      assert(!fs.existsSync(path.join 'tmp', 'main.test.litexa'),
        "main test file did not get created because it wasn't whitelisted")

    it 'applies each whitelist regex', ->
      filesHandler.syncDir({
        sourcePaths: [path.join 'common', 'litexa'],
        destination: 'tmp',
        whitelist: [
          'main.litexa$'
          'main.test.litexa$'
        ]
      })
      assert(fs.existsSync(path.join 'tmp', 'main.litexa'), 'main file was created')
      assert(fs.existsSync(path.join 'tmp', 'main.test.litexa'), 'main test file created')

    it 'reads from multiple directories and cascades files based on order', ->
      filesHandler.syncDir({
        sourcePaths: [
          path.join 'common', 'typescript', 'source'
          path.join 'bundled', 'typescript', 'source'
        ],
        destination: 'tmp',
        whitelist: ['mocha.opts$']
      })
      dataString = fs.readFileSync((path.join 'tmp', 'mocha.opts'), 'utf8')
      expect(dataString).to.include('--recursive test/')

    it 'applies the data transformation function to the files it will write', ->
      test = {
        transform: (d) -> d
      }
      transformSpy = spy(test, 'transform')

      filesHandler.syncDir({
        sourcePaths: [
          path.join 'common', 'typescript', 'config'
          path.join 'bundled', 'typescript', 'config'
        ],
        destination: 'tmp',
        whitelist: ['.*\\.json$'],
        dataTransform: test.transform
      })

      expect(transformSpy.callCount).to.equal(4)
