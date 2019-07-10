preamble = require '../preamble.coffee'

describe 'supports pronounce skill', ->
  it 'runs the pronounce integration test', ->
    preamble.runSkill 'pronounce'
