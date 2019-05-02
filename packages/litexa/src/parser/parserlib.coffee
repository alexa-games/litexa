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
