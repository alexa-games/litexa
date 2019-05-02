module.exports = (validator, skill) ->
  requiredAPIs = {}
  skill.collectRequiredAPIs requiredAPIs

  unless 'GAME_ENGINE' of requiredAPIs
    # if we didn't use any of the GAME_ENGINE statements, we have no further requirements
    return

  manifest = validator.jsonObject

  defaultJSON = {
    publishingInformation: {
      gadgetSupport: {
        requirement: "REQUIRED"
        numPlayersMin: 2
        numPlayersMax: 4
        minGadgetButtons: 2
        maxGadgetButtons: 4
      }
    }
  }

  message = (err) -> """#{err}
    #{JSON.stringify defaultJSON, null, 2}
    please see this url for information, and add it to your skill file
    https://developer.amazon.com/docs/gadget-skills/specify-echo-button-skill-details.html#manifest-fields
  """

  unless manifest.manifest.publishingInformation?.gadgetSupport?
    throw message "manifest missing required gadgetSupport key under publishingInformation"

  validator.push 'manifest', ->
    validator.push 'publishingInformation', ->
      validator.push 'gadgetSupport', ->
        validator.require ( k for k of defaultJSON.publishingInformation.gadgetSupport )
