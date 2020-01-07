{ assert, expect } = require('chai')
{ hasKeys, matchesGlobPatterns } = require('../../src/lib/utils')

describe 'Utils', ->

  describe '#hasKeys()', ->

    it 'should return false if object is undefined', ->
      expect(hasKeys(undefined, ['myKey'])).to.be.false

    it 'should return false if object is null', ->
      expect(hasKeys(null, ['myKey'])).to.be.false

    it 'should return false is object is empty', ->
      expect(hasKeys({}, ['myKey'])).to.be.false

    it 'should return false if string list is undefined', ->
      expect(hasKeys({ key: 'myValue' }, undefined)).to.be.false

    it 'should return false if string list is null', ->
      expect(hasKeys({ key: 'myValue' }, null)).to.be.false

    it 'should return false if string list is empty', ->
      expect(hasKeys({ key: 'myValue' }, [])).to.be.false

    it 'should return false if the object does not contain key that matches string in list', ->
      expect(hasKeys({ key: 'myValue' }, ['myKey'])).to.be.false

    it 'should return true if the object does contain key that matches string in list', ->
      expect(hasKeys({ key: 'myValue' }, ['key'])).to.be.true

  describe '#matchesGlobPatterns()', ->

    it 'should return false if file name is undefined', ->
      expect(matchesGlobPatterns(undefined, ['*.txt'])).to.be.false

    it 'should return false if file name is null', ->
      expect(matchesGlobPatterns(null, ['*.txt'])).to.be.false

    it 'should return false if the glob pattern list is undefined', ->
      expect(matchesGlobPatterns('myFileName.mp3', undefined)).to.be.false

    it 'should return false if the glob pattern list is null', ->
      expect(matchesGlobPatterns('myFileName.mp3', null)).to.be.false

    it 'should return false if the glob pattern list is empty', ->
      expect(matchesGlobPatterns('myFileName.mp3', [])).to.be.false

    describe 'integration test with minimatch library', ->

      it 'should return false if the file name does not match a glob pattern in the list', ->
        expect(matchesGlobPatterns('myFileName.mp3', ['*.txt'])).to.be.false

      it 'should return true if the file name does match a glob pattern in the list', ->
        expect(matchesGlobPatterns('myFileName.mp3', ['*.mp3'])).to.be.true
