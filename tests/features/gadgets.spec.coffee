assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports the gadgets API', ->
  it 'runs the gadgets-api integration test', ->
    preamble.runSkill 'apl'
