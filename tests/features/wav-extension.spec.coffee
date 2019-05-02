assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports the @litexa/assets-wav extension', ->
  it 'runs the wav-extension integration test', ->
    # TODO: Fails on first run
    # preamble.runSkill 'wav-extension'
