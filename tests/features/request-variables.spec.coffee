###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

preamble = require '../preamble.coffee'

describe 'supports request variables', ->
  it 'runs the request variables integration test', ->
    preamble.runSkill 'request-variables'
