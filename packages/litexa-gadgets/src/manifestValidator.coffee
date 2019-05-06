
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
