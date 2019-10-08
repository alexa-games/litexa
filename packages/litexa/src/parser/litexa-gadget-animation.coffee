###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

litexa.gadgetAnimation =
  # Gadget animations are for Echo Buttons right now
  # this is about animating the colors on the buttons
  # with the SetLight directive

  buildKey: (color, duration, blend) ->
    # build the inner key structure of an
    # animation to pass into directive
    color = color[1..] if color[0] == '#'
    return {
      color: color.toUpperCase()
      durationMs: duration
      blend: blend ? true
    }

  animationFromArray: (keyData) ->
    # build an animation array suitable to give
    # the directive function, from an array of
    # arrays of arguments to pass buildKey
    # e.g. [ ['FF0000',1000,true], ['00FFFF',2000,true] ]
    build = litexa.gadgetAnimation.buildKey
    for d in keyData
      build d[0], d[1], d[2]

  singleColorDirective: (targets, color, duration) ->
    animation = [
      litexa.gadgetAnimation.buildKey(color, duration, false)
    ]
    return litexa.gadgetAnimation.directive(targets, 1, animation, "none")

  resetTriggersDirectives: (targets) ->
    [
      litexa.gadgetAnimation.directive(targets, 1, [litexa.gadgetAnimation.buildKey("FFFFFF",100,false)], "buttonDown" )
      litexa.gadgetAnimation.directive(targets, 1, [litexa.gadgetAnimation.buildKey("FFFFFF",100,false)], "buttonUp" )
    ]

  directive: (targets, repeats, animation, trigger, delay) ->
    # directive to animate Echo buttons
    return
      {
        type: "GadgetController.SetLight"
        version: 1
        targetGadgets: targets
        parameters:
          triggerEvent: trigger ? "none"
          triggerEventTimeMs: delay ? 0
          animations: [
            targetLights: [ "1" ]
            repeat: repeats
            sequence: animation
          ]
      }
