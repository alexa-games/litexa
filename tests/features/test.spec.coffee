assert = require 'assert'
path = require 'path'
preamble = require '../preamble.coffee'
test = require '@litexa/core/src/command-line/test'

describe 'supports testing a skill', ->
  it 'runs a test on a simple skill', ->
    root = path.join __dirname, '..', 'data', 'simple-skill'

    options = {
      root: root
      logger: console
      dontExit: true
    }

    await test.run options

  it 'supports capturing/resuming tests', ->
    preamble.runSkill 'test-capture-resume'
