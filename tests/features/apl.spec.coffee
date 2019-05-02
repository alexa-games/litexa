assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports the @litexa/apl extension', ->
  it 'runs the apl integration test', ->
    preamble.runSkill 'apl'
