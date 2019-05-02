assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports a Hello World skill', ->
  it 'runs the hello-world integration test', ->
    preamble.runSkill 'hello-world'
