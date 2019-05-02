assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports async functions', ->
  it 'runs the async-functions integration test', ->
    preamble.runSkill 'async-functions'
