###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

pickSomething = -> 4

sumNumbers = ->
  res = 0
  for a in arguments
    res += a
  return res

ok = (value) ->
  console.log "ok! #{value}"

fail = (value) ->
  throw "FAIL #{value}"

class Thing
  constructor: ->
    @child =
      get37: -> 37

getDoormouse = -> 'doormouse'
