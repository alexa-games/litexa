###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

lib = {}

resetLib = ->
  for k of lib
    delete lib[k]

  lib.__resetLib = resetLib

  mergeLib = (required) ->
    for name, part of required.lib
      lib[name] = part

  mergeLib require("./errors.coffee")
  mergeLib require("./jsonValidator.coffee")
  mergeLib require("./dataTable.coffee")
  mergeLib require("./testing.coffee")
  mergeLib require("./variableReference.coffee")
  mergeLib require("./say.coffee")
  mergeLib require("./card.coffee")
  mergeLib require("./function.coffee")
  mergeLib require("./assets.coffee")
  mergeLib require("./soundEffect.coffee")
  mergeLib require("./intent.coffee")
  mergeLib require("./state.coffee")
  mergeLib require("./monetization.coffee")

  # reset the static index of all utterances
  lib.Intent.unregisterUtterances()

resetLib()

module.exports = lib
