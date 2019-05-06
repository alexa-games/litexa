
###

 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved.
 * These materials are licensed as "Restricted Program Materials" under the Program Materials
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service.
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html.
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized
 * terms not defined in this file have the meanings given to them in the Agreement.
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 
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

resetLib()

module.exports = lib
