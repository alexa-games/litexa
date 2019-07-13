###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

pulseButtons = ->
  directive =
    type: "GadgetController.SetLight"
    version: 1
    targetGadgets: []
    parameters:
      triggerEvent: 'none'
      triggerEventTimeMs: 0
      animations: [
        {
          repeat: 40
          targetLights: [ '1' ]
          sequence: [
            {
              durationMs: 500
              blend: true
              color: '000000'
            }
            {
              durationMs: 500
              blend: true
              color: '00FF00'
            }
          ]
        }
      ]
  [ directive ]

anyButtonHandler = ->
  type: "GameEngine.StartInputHandler"
  timeout: 1000 * 10
  proxies: [ 'one', 'two', 'three', 'four' ]
  recognizers:
    'one pressed':
      type: 'match'
      fuzzy: false
      anchor: 'end'
      pattern: [
        {
          gadgetIds: ['one']
          action: 'down'
        }
      ]
    'twopressed':
      type: 'match'
      fuzzy: false
      anchor: 'end'
      pattern: [
        {
          gadgetIds: ['two']
          action: 'down'
        }
      ]
  events:
    'button1':
      meets: [ 'one pressed' ]
      reports: 'matches'
      maximumInvocations: 100
      shouldEndInputHandler: false

    'button2':
      meets: [ 'twopressed' ]
      reports: 'matches'
      maximumInvocations: 100
      shouldEndInputHandler: false

    'finished':
      meets: [ 'timed out' ]
      reports: 'nothing'
      shouldEndInputHandler: true
