
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
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports the directive statement', ->
  it 'runs the directive integration test', ->
    preamble.runSkill 'directives'
    .then (result) ->
      response = result.raw[0].response.response
      directives = response.directives
      assert.equal directives.length, 3
      assert.equal directives[0].type, 'AudioPlayer.Play'
      assert.equal directives[1].type, 'Hint'
      assert.equal directives[2].type, 'AudioPlayer.Stop'
