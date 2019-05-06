
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


module.exports = (validator, manifest, skill) ->
  requiredAPIs = {}
  skill.collectRequiredAPIs requiredAPIs

  unless 'GAME_ENGINE' of requiredAPIs
    # if we didn't use any of the GAME_ENGINE statements, we have no further requirements
    return 

  missing = 
    'AMAZON.StopIntent': true
    'AMAZON.HelpIntent': true

  required = ( k for k of missing ).join ', '

  intents = validator.jsonObject.languageModel.intents 

  for i in intents 
    for k of missing
      if i.name == k 
        missing[k] = false

  missing = ( k for k, v of missing when v )
  return if missing.length == 0

  missing = missing.join ', '

  validator.errors.push "When using the GameEngine interface, you must also 
    implement the intents #{required}. You are currently missing any handlers 
    for #{missing}."
