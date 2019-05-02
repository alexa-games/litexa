{assert, expect} = require('chai')
{match, spy, stub} = require('sinon')

fs = require 'fs'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'

StructureCreator = require('@src/command-line/generators/directory/structureCreator')

describe 'StructureCreator', ->
  tmpDir = 'tmp'
  loggerInterface = undefined
  mkdirpInterface = undefined

  beforeEach ->
    loggerInterface = {
      log: () -> undefined
    }
    mkdirpInterface = {
      sync: () -> undefined
    }
    mkdirp.sync tmpDir

  afterEach ->
    if fs.existsSync(tmpDir)
      rimraf.sync(tmpDir)

  describe '#constructor', ->
    it 'assigns args appropriately', ->
      creator = new StructureCreator({
        logger: loggerInterface
      })

      assert(creator.hasOwnProperty('logger'), 'created logger on the object as a property')
      expect(creator.logger).to.deep.equal(loggerInterface)

  describe '#create', ->
    it 'throws an error if you try to call create directly', ->
      creator = new StructureCreator({
        logger: loggerInterface
      })

      expect(() -> creator.create()).to.throw('StructureCreator#create not implemented')

    it 'throws an error if a class that extended it does not implement #create', ->
      class MockCreator extends StructureCreator
        @description = 'Mock Creator'

      creator = new MockCreator({
        logger: loggerInterface
      })

      expect(() -> creator.create()).to.throw('MockCreator#create not implemented')

  describe '#sync', ->
    it 'throws an error if you try to call sync directly', ->
      creator = new StructureCreator({
        logger: loggerInterface
      })

      expect(() -> creator.sync()).to.throw('StructureCreator#sync not implemented')

    it 'throws an error if a class that extended it does not implement #sync', ->
      class MockCreator extends StructureCreator
        @description = 'Mock Creator'

      creator = new MockCreator({
        logger: loggerInterface
      })

      expect(() -> creator.sync()).to.throw('MockCreator#sync not implemented')

  describe '#ensureDirExists', ->
    it 'does nothing if a directory exists', ->
      mkdirSpy = spy(mkdirpInterface, 'sync')

      structureCreator = new StructureCreator({
        logger: loggerInterface,
        syncDirWriter: mkdirpInterface
      })
      structureCreator.ensureDirExists('tmp')

      assert(mkdirSpy.notCalled, 'did not write to disk')

    it "creates the directory if it doesn't exist and lets the user know", ->
      rimraf.sync(tmpDir)

      mkdirSpy = spy(mkdirpInterface, 'sync')
      logSpy = spy(loggerInterface, 'log')

      structureCreator = new StructureCreator({
        logger: loggerInterface,
        syncDirWriter: mkdirpInterface
      })
      structureCreator.ensureDirExists(tmpDir)

      assert(mkdirSpy.calledOnceWith(tmpDir), 'made call to write to disk only once')
      assert(logSpy.calledWith(match("no #{tmpDir} directory found -> creating it")),
        'informs the user that it created a directory')
