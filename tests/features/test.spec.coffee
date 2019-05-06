
###

 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved.
 * These materials are licensed as "Restricted Program Materials" under the Program Materials
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service.
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html.
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized
 * terms not defined in this file have the meanings given to them in the Agreement.
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

###


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
