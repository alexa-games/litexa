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
