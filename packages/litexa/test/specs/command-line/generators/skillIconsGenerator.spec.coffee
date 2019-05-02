{assert, expect} = require('chai')
{match, spy, stub} = require('sinon')

fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
rimraf = require 'rimraf'

SkillIconsGenerator = require('@src/command-line/generators/skillIconsGenerator')

describe 'SkillIconsGenerator', ->
  describe '#description', ->
    it 'has a class property to describe itself', ->
      assert(SkillIconsGenerator.hasOwnProperty('description'), 'has a property description')
      expect(SkillIconsGenerator.description).to.equal('skill icons')

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
      mkdirp.sync(path.join 'litexa', 'assets')

    afterEach ->
      rimraf.sync(path.join 'litexa', 'assets')

    it 'returns a promise', ->
      skillIconsGenerator = new SkillIconsGenerator({
        options,
        logger: loggerInterface
      })

      assert.typeOf(skillIconsGenerator.generate(), 'promise', 'returns a promise')

    it 'calls to create 108 and 512 sized icons', ->
      iconStub = stub(SkillIconsGenerator.prototype, '_ensureIcon').callsFake(-> undefined)
      skillIconsGenerator = new SkillIconsGenerator({
        options,
        logger: loggerInterface
      })

      skillIconsGenerator.generate()

      assert(iconStub.calledWithExactly(108), 'made call to generate 108 sized icon')
      assert(iconStub.calledWithExactly(512), 'made call to generate 512 sized icon')
      iconStub.restore()


    it 'wrote both files', ->
      skillIconsGenerator = new SkillIconsGenerator({
        options,
        logger: loggerInterface
      })

      skillIconsGenerator.generate()

      assert(fs.existsSync(path.join 'litexa', 'assets', 'icon-108.png'), 'wrote the 108 sized icon')
      assert(fs.existsSync(path.join 'litexa', 'assets', 'icon-512.png'), 'wrote the 512 sized icon')

    it 'indicates they already exist if they already exist', ->
      logSpy = spy(loggerInterface, 'log')

      skillIconsGenerator = new SkillIconsGenerator({
        options,
        logger: loggerInterface
      })

      skillIconsGenerator.generate()
      skillIconsGenerator.generate()

      assert(logSpy.calledWith(match('found -> skipping creation')),
        'indicated that the file already existed')
