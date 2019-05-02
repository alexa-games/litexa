module.exports = (validator) ->
  directive = validator.jsonObject

  if directive.type != "GameEngine.StopInputHandler"
    validator.fail 'type', "should be GameEngine.StopInputHandler"

  validator.strictlyOnly [ 'type', 'originatingRequestId' ]


