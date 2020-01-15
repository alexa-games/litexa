###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

preamble = require '../preamble.coffee'

describe 'supports the @litexa/html extension', ->
  it 'runs the html-extension integration test', ->
    preamble.runSkill 'html-extension'
