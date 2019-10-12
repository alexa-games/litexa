###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
