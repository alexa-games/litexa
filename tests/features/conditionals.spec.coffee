###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

preamble = require '../preamble.coffee'

describe 'evaluates if/else/not conditionals correctly', ->
  it 'runs the conditionals integration test', ->
    preamble.runSkill 'conditionals'
