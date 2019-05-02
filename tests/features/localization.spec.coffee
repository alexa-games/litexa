assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports languages folder overrides', ->
  it 'runs the localization integration test', ->
    preamble.runSkill 'localization'
