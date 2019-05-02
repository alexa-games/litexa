assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports card statements', ->
  it 'runs the cards integration test', ->
    preamble.runSkill 'cards'
