preamble = require '../preamble.coffee'

describe 'supports regex skill', ->
  it 'runs the regex integration test', ->
    preamble.runSkill 'regex'
