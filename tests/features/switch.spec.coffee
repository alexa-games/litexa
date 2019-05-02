assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports switch statements', ->
  it 'runs the switch integration test', ->
    preamble.runSkill 'switch'
