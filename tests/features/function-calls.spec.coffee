assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports function calls', ->
  it 'runs the function-calls integration test', ->
    preamble.runSkill 'function-calls'
