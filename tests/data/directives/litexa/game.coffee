###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

makeSingleDirective = ->
  return
    type: "AudioPlayer.Play"


makeMultipleDirectives = ->
  return [
    {
      type: "Hint"
    },
    {
      type: "AudioPlayer.Stop"
    }
  ]
