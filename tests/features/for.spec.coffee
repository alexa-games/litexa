assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports for loops', ->
  it 'runs the for loops integration test', ->
    preamble.runSkill 'for-loops'
