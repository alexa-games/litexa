###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

# WINCOMPAT: This doesn't work on Windows
# logit = require 'logger'
logit = (txt) -> console.log('logging ' + txt)

assert = (check, message) ->
  if check
    logit message
  else
    throw "FAILED: #{message}"

getDictionary = ->
  a: 'apple'
  b: 'boy'
