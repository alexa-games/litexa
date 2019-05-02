assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports the @litexa/render-template extension', ->
  it 'runs the render-template integration test', ->
    preamble.runSkill 'render-template'
