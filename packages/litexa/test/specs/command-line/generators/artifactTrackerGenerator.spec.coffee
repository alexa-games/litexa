{assert, expect} = require('chai')
{match, spy} = require('sinon')

fs = require 'fs'
Test = require('@test/helpers')
ArtifactTrackerGenerator = require('@src/command-line/generators/artifactTrackerGenerator')

describe 'ArtifactTrackerGenerator', ->
  describe '#description', ->
    it 'has a class property to describe itself', ->
      assert(ArtifactTrackerGenerator.hasOwnProperty('description'), 'has a property description')
      expect(ArtifactTrackerGenerator.description).to.equal('artifacts tracker')

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
      filename = 'artifacts.json'
      if fs.existsSync filename
        fs.unlinkSync filename

    it 'returns a promise', ->
      artifactTrackerGenerator = new ArtifactTrackerGenerator({
        options,
        logger: loggerInterface,
        artifactClass: Test.MockArtifactInterface
      })

      assert.typeOf(artifactTrackerGenerator.generate(), 'promise', 'it returns a promise')

    it 'mutates options, as a direct public side-effect', ->
      artifactTrackerGenerator = new ArtifactTrackerGenerator({
        options,
        logger: loggerInterface,
        artifactClass: Test.MockArtifactInterface
      })

      await artifactTrackerGenerator.generate()

      assert(options.hasOwnProperty('artifacts'), 'modified the options to include artifacts')
      expect(options.artifacts).to.deep.equal(Test.mockArtifact)

    it 'reads existing artifacts if they exist', ->
      fs.writeFileSync 'artifacts.json', '{"content":"json"}', 'utf8'
      logSpy = spy(loggerInterface, 'log')

      artifactTrackerGenerator = new ArtifactTrackerGenerator({
        options,
        logger: loggerInterface,
        artifactClass: Test.MockArtifactInterface
      })

      await artifactTrackerGenerator.generate()

      data = fs.readFileSync 'artifacts.json', 'utf8'
      assert(logSpy.calledOnceWith(match('existing artifacts.json found -> skipping creation')),
        'informed user the file already exists')
      assert(data == '{"content":"json"}', 'did not override file')

    it 'makes a call to saveGlobal when file exists', ->
      fs.writeFileSync 'artifacts.json', '{"content":"json"}', 'utf8'
      constructorSpy = spy(Test, 'MockArtifactInterface')
      saveSpy = spy(Test.MockArtifactInterface.prototype, 'saveGlobal')

      artifactTrackerGenerator = new ArtifactTrackerGenerator({
        options,
        logger: loggerInterface,
        artifactClass: Test.MockArtifactInterface
      })

      await artifactTrackerGenerator.generate()

      assert(constructorSpy.calledWithNew(), 'instantiated artifact class')
      assert(constructorSpy.calledWith('artifacts.json', { "content": "json" }),
        'called the constructor with the right arguments')
      assert(saveSpy.calledOnceWith('last-generated', match.number),
        'called save spy with appropriate arguments')

      constructorSpy.restore()
      saveSpy.restore()

    it 'makes a call to saveGlobal when file does not', ->
      constructorSpy = spy(Test, 'MockArtifactInterface')
      saveSpy = spy(Test.MockArtifactInterface.prototype, 'saveGlobal')

      artifactTrackerGenerator = new ArtifactTrackerGenerator({
        options,
        logger: loggerInterface,
        artifactClass: Test.MockArtifactInterface
      })

      await artifactTrackerGenerator.generate()

      assert(constructorSpy.calledWithNew(), 'instantiated artifact class')
      assert(constructorSpy.calledWith('artifacts.json', {}),
        'called the constructor with the right arguments')
      assert(saveSpy.calledOnceWith('last-generated', match.number),
        'called save spy with appropriate arguments')

      constructorSpy.restore()
      saveSpy.restore()
