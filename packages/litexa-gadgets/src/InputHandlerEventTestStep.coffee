
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


uuid = require('uuid')


makeHandlerIdentity = (skill) ->
  event = makeBaseRequest(skill)
  identity = {}
  if event.context?.System?
    identity.requestAppId = event.context.System.application?.applicationId
    identity.userId = event.context.System.user?.userId
    identity.deviceId = event.context.System.device?.deviceId
  else if event.session?
    identity.requestAppId = event.session.application?.applicationId
    identity.userId = event.session.user?.userId
    identity.deviceId = 'no-device'
  return identity

makeRequestId = ->
  "litexaRequestId.#{uuid.v4()}"

makeBaseRequest = (skill) ->
  # all requests start out looking like this
  req = {
    session:
      sessionId: "SessionId.uuid",
      application:
        applicationId: "amzn1.ask.skill.uuid"
      attributes: {},
      user:
        userId: "amzn1.ask.account.stuff"
      new: true
    context:
      System:
        device:
          deviceId: "someDeviceId"
        user:
          userId: "amzn1.ask.account.stuff"
        application:
          applicationId: "amzn1.ask.skill.uuid"
    request : null
    version: "1.0"
  }
  device = skill.testDevice ? 'dot'

  switch device
    when 'dot', 'echo'
      dev = req.context.System.device
    when 'show'
      dev = req.context.System.device
      dev.supportedInterfaces =
        Display: {}
    else
      throw new Error "Unknown test device type #{device}"

  return req

makeInputHandlerEventRequest = (skill, event, time, locale) ->
  req = makeBaseRequest(skill)
  if event.game_mode
    req.request =
      type: "GameEngine.InputHandlerEvent"
      requestId: makeRequestId()
      timestamp: new Date(time).toISOString()
      locale: locale
      payload: event
  else
    req.request =
      type: "GameEngine.InputHandlerEvent"
      requestId: makeRequestId()
      timestamp: new Date(time).toISOString()
      locale: locale
      events: event
  return req

padString = (str, len, ch) ->
  str = str ? "MISSINGSTRING"
  # insert ch into str so that its length is len
  pre = Math.floor( (str.length - len) / 2 )
  for i in [0...pre]
    str = ch + str
  while str.length < len
    str += ch
  return str


class TrapLog
  constructor: (passLog, passError) ->
    @logs = logs = []
    @errors = errors = []
    @oldLog = oldLog = console.log
    @oldError = oldError = console.error
    console.log = ->
      for a in arguments
        if typeof(a) == 'string'
          logs.push a
          if passLog?
            passLog a
        else
          text = JSON.stringify(a)
          logs.push text
          if passLog?
            passLog text

    console.error = ->
      for a in arguments
        errors.push a
        if passError?
          passError a

  stop: (flush) ->
    console.log = @oldLog
    console.error = @oldError
    if flush
      console.log @logs.join('\n')
      console.error @errors.join('\n')


class ResponseGeneratingStep
  constructor: ->
    @expectations = []

  isResponseGeneratingStep: true

  pushExpectation: (obj) ->
    @expectations.push obj

  checkForSessionEnd: ->
    should = null
    shouldnot = null
    for e in @expectations
      if e.isExpectedContinueSession
        should = e
      if e.isExpectedEndSession
        shouldnot = e
    if should? and shouldnot?
      throw new Error "TestError: step expects the session to end and not to end"
    unless should?
      unless shouldnot?
        @expectations.push new lib.ExpectedContinueSession @location

  makeResult: ->
    {
      expectationsMet: true
      errors: []
      logs: []
    }

  processEvent: (result, skill, lambda, context, resultCallback) ->
    event = result.event
    event.session.attributes = context.attributes
    trap = null

    try
      trap = new TrapLog
      lambda.handler event, {}, (err, data) =>
        trap.stop(false)

        cleanSpeech = (data) ->
          speech = data?.text
          unless speech
            speech = data?.ssml
            if speech
              speech = speech.replace "<speak>", ''
              speech = speech.replace "</speak>", ''
          return speech

        result.err = err
        result.data = data
        result.speech = cleanSpeech result.data?.response?.outputSpeech
        if result.data?.response?.reprompt?
          result.reprompt = cleanSpeech result.data.response.reprompt.outputSpeech
        if result.data?.sessionAttributes?
          context.attributes = result.data.sessionAttributes

        if result.data?.response?.card?
          card = result.data?.response?.card
          result.card = card
          result.cardReference = card.title

        if result.data?.response?.directives?
          result.directives = []
          for d, index in result.data.response.directives
            if typeof(d) != 'object'
              result.errors.push "directive #{index} was not even an object. Pushed something wrong into the array?"
              continue

            try
              result.directives.push JSON.parse JSON.stringify d
            catch err
              result.errors.push "directive #{index} could not be JSON serialized, maybe contains circular reference and or non primitive values?"

        for expectation in @expectations
          try
            expectation.test( skill, context, result )
          catch ex
            result.errors.push ex.message
            result.expectationsMet = false

        result.logs.push l for l in trap.logs
        result.errors.push e for e in trap.errors
        result.shouldEndSession = result.data?.response?.shouldEndSession
        resultCallback null, result

    catch ex
      trap.stop(true) if trap?
      result.err = ex
      if trap?
        result.logs.push l for l in trap.logs
        result.errors.push e for e in trap.errors
      resultCallback ex, result


class InputHandlerEventTestStep extends ResponseGeneratingStep
  constructor: (@location, source) ->
    super()
    if typeof(source) == 'string'
      @eventNames = [ source ]
    else if Array.isArray(source)
      @eventNames = source
    else
      @sourceFilename = source.toString()

    # oh lets say there's some kind of fixed cadence of
    # at least 30 seconds between the usual input events
    @testingTimeIncrement = 30 * 1000
    @isInputHandlerEventTestStep = true

  pushAction: (location, gadgetId, action, color) ->
    @actions = @actions ? []
    @actions.push {
      gadgetId: gadgetId
      color: color
      feature: 'press'
      action: action
      # timestamp
    }

  run: (skill, lambda, context, resultCallback) ->
    if @sourceFilename
      source = skill.getFileContents(@sourceFilename, skill.testLanguage)
      unless source?
        resultCallback new Error ("no source found for InputHandlerEvent `#{@sourceFilename}`")
        return

      if Array.isArray(source)
        directives = source
      else if typeof(source) == 'object'
        directives = [ source ]
      else
        resultCallback new Error ("InputHandlerEvent `#{@sourceFilename}` didn't contain the expected array of input handler events. See litexa-gadgets/readme.md for instructions.")
        return

      names = []
      count = 0
      for d in directives
        names.push d.name
        if d.inputEvents
          count += d.inputEvents.length
      @description = "#{names.join(',')}[#{count}]"

    else
      directives = for name in @eventNames
        {
          name: name
          inputEvents: @actions ? []
        }
      @description = "#{@eventName}[#{@actions?.length ? 0}]"

    result = @makeResult()
    result.directive = directives
    result.event = makeInputHandlerEventRequest(skill, directives, context.time, skill.testLanguage)
    result.event.request.originatingRequestId = context.db.getVariables(makeHandlerIdentity(skill)).__lastInputHandler
    @processEvent result, skill, lambda, context, resultCallback

  report: (err, loc, sourceLine, step, output, result, context) ->
    skill = context.skill
    if err
      loc.push "#{sourceLine}  ⦿⦿ #{err}"
    else
      time = (new Date(context.time)).toLocaleString()
      if result.directive?
        if Array.isArray(result.directive)
          name = ( event.name for event in result.directive ).join(', ')
        else
          name = "V1GameEngine"
        padded = padString(name, skill.maxStateNameLength+2, ' ')
      else
        padded = padString("MISSING EVENT", skill.maxStateNameLength+2, ' ')

      loc.push "#{sourceLine}  ⦿⦿ #{padded} #{step.sourceFilename ? ''} @ #{time}"


module.exports = InputHandlerEventTestStep
