###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

{assert, expect} = require('chai')
{match, spy} = require('sinon')

fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
rimraf = require 'rimraf'

AssetsDirectoryGenerator = require('@src/command-line/generators/assetsDirectoryGenerator')

describe 'AssetsDirectoryGenerator', ->
  describe '#description', ->
    it 'has a class property to describe itself', ->
      assert(AssetsDirectoryGenerator.hasOwnProperty('description'), 'has a property description')
      expect(AssetsDirectoryGenerator.description).to.equal('assets directory')

  describe '#generate', ->
    loggerInterface = undefined
    options = undefined

    beforeEach ->
      options = {
        root: '.'
      }
      loggerInterface = {
        log: () -> undefined
      }

    afterEach ->
      dirname = path.join 'litexa', 'assets'
      if fs.existsSync dirname
        rimraf.sync dirname

    it 'returns a promise', ->
      assetsDirectoryGenerator = new AssetsDirectoryGenerator({
        options,
        logger: loggerInterface
      })

      assert.typeOf(assetsDirectoryGenerator.generate(), 'promise', 'it returns a promise')

    it "doesn't create it if it already exists", ->
      mkdirp.sync(path.join 'litexa', 'assets')

      logSpy = spy(loggerInterface, 'log')

      assetsDirectoryGenerator = new AssetsDirectoryGenerator({
        options,
        logger: loggerInterface
      })

      await assetsDirectoryGenerator.generate()

      assert(logSpy.calledWith(match('existing litexa/assets directory found')),
        'it lets the user know the directory already exists')
      assert(logSpy.neverCalledWith(match('creating litexa/assets')),
        'it does not misinform the user')

    it "creates it if doesn't exist", ->
      logSpy = spy(loggerInterface, 'log')

      assetsDirectoryGenerator = new AssetsDirectoryGenerator({
        options,
        logger: loggerInterface
      })

      await assetsDirectoryGenerator.generate()

      assert(logSpy.neverCalledWith(match('existing litexa/assets directory found')),
        'it lets the user know the directory already exists')
      assert(logSpy.calledWith(match('creating litexa/assets')),
        'it does not misinform the user')

      assert(fs.existsSync(path.join 'litexa', 'assets'), 'it created the directory')
