
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

describe 'supports the playMusic and stopMusic statements', ->
  it 'runs the sound integration test', ->
    preamble.runSkill 'sound'
    .then (result) ->
      # result[0] is blank launch response

      response = result.raw[1].response.response
      directives = response.directives
      assert.equal directives.length, 1
      assert.equal directives[0].type, 'AudioPlayer.Play'
      assert.equal directives[0].audioItem?.stream?.url, 'test://default/sound.mp3'

      response = result.raw[2].response.response
      directives = response.directives
      assert.equal directives.length, 1
      assert.equal directives[0].type, 'AudioPlayer.Play'
      assert.equal directives[0].audioItem?.stream?.url, 'https://www.example.com/sound.mp3'

      response = result.raw[3].response.response
      directives = response.directives
      assert.equal directives.length, 1
      assert.equal directives[0].type, 'AudioPlayer.Stop'
