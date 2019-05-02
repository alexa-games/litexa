assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports lexical scoping', ->
  it 'runs the lexical-scoping integration test', ->
    preamble.runSkill 'lexical-scoping'
