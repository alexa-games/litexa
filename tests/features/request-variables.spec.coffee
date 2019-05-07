assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports request variables', ->
  it 'runs the request variables integration test', ->
    preamble.runSkill 'request-variables'
