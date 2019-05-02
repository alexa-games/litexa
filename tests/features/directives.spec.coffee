assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports the directive statement', ->
  it 'runs the directive integration test', ->
    preamble.runSkill 'directives'
    .then (result) ->
      response = result.raw[0].response.response
      directives = response.directives
      assert.equal directives.length, 3
      assert.equal directives[0].type, 'AudioPlayer.Play'
      assert.equal directives[1].type, 'Hint'
      assert.equal directives[2].type, 'AudioPlayer.Stop'
