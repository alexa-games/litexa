colorRegex = /^[A-F0-9]{6}$/
maximumHandlerDurationMilliseconds = 5 * 60 * 1000 # 5 minutes


module.exports = (validator) ->
  directive = validator.jsonObject

  requiredKeys = [ 'type', 'timeout', 'recognizers', 'events' ]
  optionalKeys = [ 'comment', 'proxies', 'maximumHistoryLength', 'gadgets' ]

  validator.require requiredKeys
  validator.whiteList requiredKeys.concat optionalKeys

  if directive.type != "GameEngine.StartInputHandler"
    validator.fail 'type', "should be GameEngine.StartInputHandler"

  if directive.maximumHistoryLength?
    validator.integerBounds 'maximumHistoryLength', 0, 2048

  validator.integerBounds 'timeout', 0, maximumHandlerDurationMilliseconds

  unless typeof(directive.recognizers) == 'object'
    validator.fail 'recognizers', "should be an object"
  unless typeof(directive.events) == 'object'
    validator.fail 'events', "should be an object"

  if directive.gadgets?
    if Array.isArray(directive.gadgets)
      for gadgetId, idx in directive.gadgets
        unless typeof(gadgetId) == 'string'
          validator.fail "gadgets[#{idx}]", "should be a string"
    else
      validator.fail 'gadgets', "should be an array"

  for name, recognizer of directive.recognizers
    validator.push 'recognizers', ->
      validator.push name, ->
        validateRecognizer(directive, name, recognizer, validator)

  for name, event of directive.events
    validator.push 'events', ->
      validator.push name, ->
        validateEvent(directive, name, event, validator)


validateEvent = (directive, name, event, validator) ->
  validator.whiteList [ 'meets', 'fails', 'reports'
    'shouldEndInputHandler', 'comment', 'maximumInvocations'
    'triggerTimeMilliseconds' ]

  builtInRecognizers = [ 'timed out' ]
  if event.meets?
    if Array.isArray(event.meets)
      for recognizer, idx in event.meets
        unless recognizer of directive.recognizers or recognizer in builtInRecognizers
          validator.fail "meets[#{idx}]", "recognizer not found in the recognizers object"
    else
      validator.fail "meets", "should be an array of recognizer names"

  if event.fails?
    if Array.isArray(event.fails)
      for recognizer, idx in event.fails
        unless recognizer of directive.recognizers or recognizer in builtInRecognizers
          validator.fail "fails[#{idx}]", "recognizer not found in the recognizers object"
    else
      validator.fail "fails", "should be an array of recognizer names"

  validator.oneOf 'reports', [ 'matches', 'history', 'nothing' ]

  if event.maximumInvocations?
    validator.integerBounds 'maximumInvocations', 1, 2048

  if event.triggerTimeMilliseconds?
    validator.integerBounds 'triggerTimeMilliseconds', 0,maximumHandlerDurationMilliseconds

  if event.triggerTimeMilliseconds? and event.maximumInvocations?
    validator.fail "triggerTimeMilliseconds", "should not be present if `maximumInvocations` is also present"

  validator.boolean 'shouldEndInputHandler'

  return null


validateRecognizer = (directive, name, recognizer, validator) ->
  type = recognizer.type
  validatorFunction = recognizers[type]
  unless validatorFunction?
    validator.fail "type", "unrecognized recognizer type"
    return
  validatorFunction(directive, recognizer, name, validator)


recognizers =
  match: (directive, r, name, validator) ->
    validator.whiteList [ 'type', 'fuzzy', 'anchor', 'pattern', 'comment', 'gadgetIds', 'actions' ]

    if r.anchor?
      validator.oneOf 'anchor', ['start', 'end', 'anywhere']

    if r.fuzzy?
      validator.boolean 'fuzzy'

    if r.gadgetIds?
      if Array.isArray(r.gadgetIds)
        for gadgetId, idx in r.gadgetIds
          unless typeof(gadgetId) == 'string'
            validator.fail "gadgetIds[#{idx}]", "should be a string"
      else
        validator.fail 'gadgetIds', "should be an array of gadgetId strings"

    unless 'pattern' of r
      validator.fail 'pattern', "must have a pattern array"

    validActions = [ 'up', 'down' ]
    if r.actions?
      if Array.isArray(r.actions)
        for action, idx in r.actions
          validator.oneOf "actions[#{idx}]", validActions
      else
        validator.fail 'actions', "should be an array of actions to include, e.g. ['up', 'down']"

    for p, idx in r.pattern
      validator.push 'pattern', ->
        validator.push idx, ->
          validator.whiteList ['gadgetIds', 'action', 'colors', 'repeat']

          if p.action?
            validator.oneOf "action", validActions

          if p.colors?
            if Array.isArray(p.colors)
              for color, cidx in p.colors
                unless colorRegex.exec(color)
                  validator.fail "colors[#{cidx}]", "should be a color in the format FFFFFF"
            else
              validator.fail "colors", "should be an array of acceptable colors"

          if p.repeat?
            validator.integerBounds 'repeat', 1, 99999

          if p.gadgetIds?
            if Array.isArray(p.gadgetIds)
              for gadgetId, gidx in p.gadgetIds
                unless typeof(gadgetId) == 'string'
                  validator.fail "gadgetIds[#{gidx}]", "should be a string"
            else
              validator.fail 'gadgetIds', "should be an array of gadgetId strings"


  deviation: (directive, r, name, validator) ->
    validator.whiteList [ 'type', 'recognizer' ]
    unless r.recognizer of directive.recognizers
      validator.fail "recognizer", "recognizer not found in the recognizers object"

  progress: (directive, r, name, validator) ->
    validator.whiteList [ 'type', 'recognizer', 'completion' ]
    unless r.recognizer of directive.recognizers
      validator.fail "recognizer", "recognizer not found in the recognizers object"
    validator.integerBounds 'completion', 0, 100
