preamble = require '../preamble.coffee'

describe 'supports Tag Testing skill', ->
  it 'runs the tag-test integration test', ->
    preamble.runSkill 'tag-test'
