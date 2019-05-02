hexColorRegex = /^(?:0x|#)?([A-Fa-f0-9]{6})$/

module.exports = (validator) ->

  directive = validator.jsonObject

  validator.require ['type', 'version', 'parameters']

  unless directive.type == 'GadgetController.SetLight'
    validator.fail "type", "should only be `GadgetController.SetLight`"

  unless directive.version == 1
    validator.fail "version", "should be exactly the number 1"

  if directive.targetGadgets?
    if Array.isArray(directive.targetGadgets)
        for gadgetId, idx in directive.targetGadgets
          # TODO: come back and see about validating gadgetId forms?
          unless typeof(gadgetId) == 'string'
            validator.fail "targetGadgets[#{idx}]", "should be a string"
    else
      validator.fail "targetGadgets", "should be an array"

  checkSetLightParameters directive, validator

  # TODO: validate maximum directive size we can support


commandValidators = {}

checkSetLightParameters = (directive, validator) ->
  parameters = directive.parameters
  validator.push 'parameters', ->
    triggerNames = ['none', 'buttonDown', 'buttonUp']
    unless parameters.triggerEvent in triggerNames
      validator.fail "triggerEvent", "should be one of #{JSON.stringify(triggerNames)}"

    unless parameters.animations?
      validator.fail "animations", "missing animations"

    validator.push "animations", ->
      for anim, animIndex in parameters.animations
        validator.push animIndex, ->
          checkSetLEDAnimation anim, validator



checkSetLEDAnimation = (anim, validator) ->
  validator.require ['repeat', 'sequence', 'targetLights']

  unless typeof(anim.repeat) == 'number'
    validator.fail "repeat", "should be a number"

  if Array.isArray(anim.targetLights)
    if anim.targetLights.length != 1
      validator.fail "targetLights should have size of 1"
    validator.push "targetLights", ->
      for lightId, idx in anim.targetLights
        unless typeof(lightId) == 'string'
          validator.fail idx, "should be a string"
        if lightId != "1"
          validator.fail idx, "should be '1'"
  else
    validator.fail "targetLights", "should be an array"

  if Array.isArray(anim.sequence)
    unless anim.sequence.length <= 38
      # as of 10/1/2017, limited to 38 keys
      # TODO incorporate the cost of targetIDs
      validator.failNoValue "sequence", "at most only 38 entries are supported in a single animation sequence, found #{anim.sequence.length}"

    validator.push 'sequence', ->
      for key, keyIndex in anim.sequence
        validator.push keyIndex, ->
          checkSetLEDKey key, keyIndex, validator
  else
    validator.fail "sequence", "should be an array"


checkSetLEDKey = (key, keyIndex, validator) ->
  validator.whiteList ['color', 'durationMs', 'blend', 'intensity']

  if key.color?
    unless hexColorRegex.exec(key.color)
      validator.fail "color", "bad format, must be in the form 0xFFFFFF"
  else
      validator.fail "color", "parameter is missing, should be in the form 0xFFFFFF"

  if key.durationMs?
    validator.integerBounds "durationMs", 1, 65535
  else
    validator.fail "durationMs", "parameter is missing, should be an integer between 0 and 65535, inclusive"

  if key.blend?
    unless key.blend in [true, false]
      validator.fail "blend", "must be either true or false"
  else
      validator.fail "blend", "parameter is missing, must be either true or false"

  if key.intensity?
    unless key.intensity == 255
      validator.fail "intensity", "parameter is being deprecated, if present it must be exactly the value 255"
