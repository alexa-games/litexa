assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports extensions', ->
  it 'supports various extension architectures', ->
    preamble.runSkill 'extensions'
