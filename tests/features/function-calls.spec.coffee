###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports function calls', ->
  it 'runs the function-calls integration test', ->
    preamble.runSkill 'function-calls'
