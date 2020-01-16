###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

# causes every request and response object to be written to the logs
loggingLevel = process?.env?.loggingLevel ? null

# when enabled, logs out every state transition when it happens, useful for tracing what
# order things happened in  when something goes wrong
logStateTraces = process?.env?.logStateTraces in [ 'true', true ]
enableStateTracing = (process?.env?.enableStateTracing in [ 'true', true ]) or logStateTraces

# hack for over aggressive Show caching
shouldUniqueURLs = process?.env?.shouldUniqueURLs == 'true'

# assets root location is determined by an external variable
litexa.assetsRoot = process?.env?.assetsRoot ? litexa.assetsRoot

handlerSteps = {}

exports.handler = (event, lambdaContext, callback) ->

  handlerContext =
    originalEvent: event
    litexa: litexa

  # patch for testing support to be able to toggle this without
  # recreating the lambda
  if event.__logStateTraces?
    logStateTraces = event.__logStateTraces

  switch loggingLevel
    when 'verbose'
      # when verbose logging, dump the whole event to the console
      # this is pretty quick, but it makes for massive logs
      exports.Logging.log "VERBOSE REQUEST " + JSON.stringify(event, null, 2)
    when 'terse'
      exports.Logging.log "VERBOSE REQUEST " + JSON.stringify(event.request, null, 2)

  # patch when missing so downstream doesn't have to check
  unless event.session?
    event.session = {}
  unless event.session.attributes?
    event.session.attributes = {}


  handlerSteps.extractIdentity(event, handlerContext)
  .then ->
    handlerSteps.checkFastExit(event, handlerContext)
  .then (proceed) ->
    unless proceed
      return callback null, {}

    handlerSteps.runConcurrencyLoop(event, handlerContext)
    .then (response) ->
      # if we have post process extensions, then run each one in series
      promise = Promise.resolve()
      for extensionName, events of extensionEvents
        if events.beforeFinalResponse?
          try
            await events.beforeFinalResponse response
          catch err
            exports.Logging.error "Failed to execute the beforeFinalResponse
              event for extension #{extensionName}: #{err}"
            throw err
      return response
    .then (response) ->
      # if we're fully resolved here, we can return the final result
      if loggingLevel
        exports.Logging.log "VERBOSE RESPONSE " + JSON.stringify(response, null, 2)
      callback null, response
    .catch (err) ->
      # otherwise, we've failed, so return as an error, without data
      callback err, null


handlerSteps.extractIdentity = (event, handlerContext) ->
  new Promise (resolve, reject) ->
    # extract the info we consider to be the user's identity. Note
    # different events may provide this information in different places
    handlerContext.identity = identity = {}
    if event.context?.System?
      identity.requestAppId = event.context.System.application?.applicationId
      identity.userId = event.context.System.user?.userId
      identity.deviceId = event.context.System.device?.deviceId
    else if event.session?
      identity.requestAppId = event.session.application?.applicationId
      identity.userId = event.session.user?.userId
      identity.deviceId = 'no-device'
    resolve()


handlerSteps.checkFastExit = (event, handlerContext) ->

  # detect fast exit for valid events we don't route yet, or have no response to
  terminalEvent = false
  switch event.request.type
    when 'System.ExceptionEncountered'
      exports.Logging.error "ERROR System.ExceptionEncountered: #{JSON.stringify(event.request)}"
      terminalEvent = true
    when 'SessionEndedRequest'
      terminalEvent = true

  unless terminalEvent
    return true

  # this is an event that ends the session, but we may have code
  # that needs to cleanup on skill exist that result in a BD write
  new Promise (resolve, reject) ->
    tryToClose = ->
      dbKey = litexa.overridableFunctions.generateDBKey(handlerContext.identity)

      db.fetchDB { identity: handlerContext.identity, dbKey, fetchCallback: (err, dbObject) ->
        if err?
          return reject(err)

        # todo, insert any new skill cleanup code here
        #   check to see if dbObject needs flushing

        # all clear, we don't have anything active
        if loggingLevel
          exports.Logging.log "VERBOSE Terminating input handler early"

        return resolve(false)

        # write back the object, to clear our memory
        dbObject.finalize (err) ->
          return reject(err) if err?
          if dbObject.repeatHandler
            tryToClose()
          else
            return resolve(false)
      }
    tryToClose()


handlerSteps.runConcurrencyLoop = (event, handlerContext) ->

  # to solve for concurrency, we keep state in a database
  # and support retrying all the logic after this point
  # in the event that the database layer detects a collision

  return new Promise (resolve, reject) ->
    numberOfTries = 0
    requestTimeStamp = (new Date(event.request?.timestamp)).getTime()

    # work out the language, from the locale, if it exists
    language = 'default'
    if event.request.locale?
      lang = event.request.locale
      langCode = lang[0...2]

      for __language of __languages
        if (lang.toLowerCase() is __language.toLowerCase()) or (langCode is __language)
          language = __language

    litexa.language = language
    handlerContext.identity.litexaLanguage = language

    runHandler = ->
      numberOfTries += 1
      if numberOfTries > 1
        exports.Logging.log "CONCURRENCY LOOP iteration #{numberOfTries}, denied db write"

      dbKey = litexa.overridableFunctions.generateDBKey(handlerContext.identity)

      db.fetchDB { identity: handlerContext.identity, dbKey, fetchCallback: (err, dbObject) ->
        # build the context object for the state machine
        try

          stateContext =
            say: []
            reprompt: []
            directives: []
            shouldEndSession: false
            now: requestTimeStamp
            settings: {}
            traceHistory: []
            requestId: event.request.requestId
            language: language
            event: event
            request: event.request ? {}
            db: new DBTypeWrapper dbObject, language

          stateContext.settings = stateContext.db.read("__settings") ? { resetOnLaunch: true }

          unless dbObject.isInitialized()
            dbObject.initialize()
            await __languages[stateContext.language].enterState.initialize?(stateContext)

          await handlerSteps.parseRequestData stateContext
          await handlerSteps.initializeMonetization stateContext, event
          await handlerSteps.routeIncomingIntent stateContext
          await handlerSteps.walkStates stateContext
          response = await handlerSteps.createFinalResult stateContext

          if event.__reportStateTrace
            response.__stateTrace = stateContext.traceHistory

          if dbObject.repeatHandler
            # the db failed to save, repeat the whole process
            await runHandler()
          else
            resolve response

        catch err
          reject err
      }

    # kick off the first one
    await runHandler()


handlerSteps.parseRequestData = (stateContext) ->
  request = stateContext.request

  # this is litexa's dynamic request context, i.e. accesible from litexa as $something
  stateContext.slots =
    request: request

  stateContext.oldInSkillProducts = stateContext.inSkillProducts = stateContext.db.read("__inSkillProducts") ? { inSkillProducts: [] }

  # note:
  # stateContext.handoffState  : who will handle the next intent
  # stateContext.handoffIntent : which intent will be delivered next
  # stateContext.currentState  : which state are we ALREADY in
  # stateContext.nextState     : which state is queued up to be transitioned into next

  stateContext.handoffState = null
  stateContext.handoffIntent = false
  stateContext.currentState = stateContext.db.read "__currentState"
  stateContext.nextState = null

  if request.type == 'LaunchRequest'
    reportValueMetric 'Launches'

  switch request.type
    when 'IntentRequest', 'LaunchRequest'
      incomingState = stateContext.currentState

      # don't have a current state? Then we're going to launch
      unless incomingState
        incomingState = 'launch'
        stateContext.currentState = null

      isColdLaunch = request.type == 'LaunchRequest' or stateContext.event.session?.new
      if stateContext.settings.resetOnLaunch and isColdLaunch
        incomingState = 'launch'
        stateContext.currentState = null

      if request?.intent
        intent = request.intent
        stateContext.intent = intent.name
        if intent.slots?
          for name, obj of intent.slots
            stateContext.slots[name] = obj.value
            auth = obj.resolutions?.resolutionsPerAuthority?[0]
            if auth? and auth.status?.code == 'ER_SUCCESS_MATCH'
              value = auth.values?[0]?.value?.name
              if value?
                stateContext.slots[name] = value

        stateContext.handoffIntent = true
        stateContext.handoffState = incomingState
        stateContext.nextState = null
      else
        stateContext.intent = null
        stateContext.handoffIntent = false
        stateContext.handoffState = null
        stateContext.nextState = incomingState

    when 'Connections.Response'
      stateContext.handoffIntent = true

      # if we get this and we're not in progress,
      # then reroute to the launch state
      if stateContext.currentState?
        stateContext.handoffState = stateContext.currentState
      else
        stateContext.nextState = 'launch'
        stateContext.handoffState = 'launch'

    else
      stateContext.intent = request.type
      stateContext.handoffIntent = true
      stateContext.handoffState = stateContext.currentState
      stateContext.nextState = null

      handled = false

      for extensionName, requests of extensionRequests
        if request.type of requests
          handled = true
          func = requests[request.type]
          if typeof(func) == 'function'
            func(request)

      if request.type in litexa.extendedEventNames
        handled = true

      unless handled
        throw new Error "unrecognized event type: #{request.type}"

  initializeExtensionObjects stateContext


handlerSteps.initializeMonetization = (stateContext, event) ->
  stateContext.monetization = stateContext.db.read("__monetization")
  unless stateContext.monetization?
    stateContext.monetization = {
      fetchEntitlements: false
      inSkillProducts: []
    }
    stateContext.db.write "__monetization", stateContext.monetization

  if event.request?.type in [ 'Connections.Response', 'LaunchRequest' ]
    attributes = event.session.attributes
    # invalidate monetization cache
    stateContext.monetization.fetchEntitlements = true
    stateContext.db.write "__monetization", stateContext.monetization

  if event.request?.type == 'Connections.Response'
    stateContext.intent = 'Connections.Response'
    stateContext.handoffIntent = true
    stateContext.handoffState = 'launch'
    stateContext.nextState = 'launch'

  return Promise.resolve()


handlerSteps.routeIncomingIntent = (stateContext) ->
  if stateContext.nextState
    unless stateContext.nextState of __languages[stateContext.language].enterState
      # we've been asked to execute a non existant state!
      # in order to have a chance at recovering, we have to drop state
      # which means when next we launch we'll start over

      # todo: reroute to launch anyway?
      await new Promise (resolve, reject) ->
        stateContext.db.write "__currentState", null
        stateContext.db.finalize (err) ->
          reject new Error "Invalid state name `#{stateContext.nextState}`"

  # if we have an intent, handle it with the current state
  # but if that handler sets a handoff, then following that
  # and keep following them until we've actually handled it
  for i in [0...10]
    return unless stateContext.handoffIntent
    stateContext.handoffIntent = false

    if enableStateTracing
      item = "#{stateContext.handoffState}:#{stateContext.intent}"
      stateContext.traceHistory.push item

    if logStateTraces
      item = "drain intent #{stateContext.intent} in #{stateContext.handoffState}"
      exports.Logging.log "STATETRACE " + item

    await __languages[stateContext.language].processIntents[stateContext.handoffState]?(stateContext)


  throw new Error "Intent handler recursion error, exceeded 10 steps"


handlerSteps.walkStates = (stateContext) ->

  # keep processing state transitions until we're done
  MaximumTransitionCount = 500
  for i in [0...MaximumTransitionCount]
    nextState = stateContext.nextState
    stateContext.nextState = null

    unless nextState
      return

    lastState = stateContext.currentState
    stateContext.currentState = nextState
    if lastState?
      await __languages[stateContext.language].exitState[lastState](stateContext)

    if enableStateTracing
      stateContext.traceHistory.push nextState

    if logStateTraces
      item = "enter #{nextState}"
      exports.Logging.log "STATETRACE " + item

    unless nextState of __languages[stateContext.language].enterState
      throw new Error "Transitioning to an unknown state `#{nextState}`"
    await __languages[stateContext.language].enterState[nextState](stateContext)

    if stateContext.handoffIntent
      stateContext.handoffIntent = false
      if enableStateTracing
        stateContext.traceHistory.push stateContext.handoffState
      if logStateTraces
        exports.Logging.log "STATETRACE " + item
      await __languages[stateContext.language].processIntents[stateContext.handoffState]?(stateContext)

  exports.Logging.error "States error: exceeded #{MaximumTransitionCount} transitions."
  if enableStateTracing
    exports.Logging.error "States visited: [#{stateContext.traceHistory.join(' -> ')}]"
  else
    exports.Logging.error "Set 'enableStateTracing' to get a history of which states were visited."

  throw new Error "States error: exceeded #{MaximumTransitionCount} transitions.
    Check your logic for non-terminating loops."


handlerSteps.createFinalResult = (stateContext) ->

  stripSSML = (line) ->
    return undefined unless line?
    line = line.replace /<[^>]+>/g, ''
    line.replace /[ ]+/g, ' '

  # invoke any 'afterStateMachine' extension events
  for extensionName, events of extensionEvents
    try
      await events.afterStateMachine?()
    catch err
      exports.Logging.error "Failed to execute afterStateMachine
        for extension #{extensionName}: #{err}"
      throw err

  hasDisplay = stateContext.event.context?.System?.device?.supportedInterfaces?.Display?

  # start building the final response json object
  wrapper =
    version: "1.0"
    sessionAttributes: {}
    userAgent: userAgent # this userAgent value is generated in project-info.coffee and injected in skill.coffee
    response:
      shouldEndSession: stateContext.shouldEndSession

  response = wrapper.response

  if stateContext.shouldDropSession
    delete response.shouldEndSession

  # build outputSpeech and reprompt from the accumulators
  joinSpeech = (arr, language = 'default') ->
    return '' unless arr
    result = arr[0]
    for line in arr[1..]
      # If the line starts with punctuation, don't add a space before.
      if line.match /^[?!:;,.]/
        result += line
      else
        result += " #{line}"

    result = result.replace /(  )/g, ' '
    if litexa.sayMapping[language]
      for mapping in litexa.sayMapping[language]
        result = result.replace mapping.from, mapping.to
    return result

  if stateContext.say? and stateContext.say.length > 0
    response.outputSpeech =
      type: "SSML"
      ssml: "<speak>#{joinSpeech(stateContext.say, stateContext.language)}</speak>"
      playBehavior: "REPLACE_ALL"

  if stateContext.repromptTheSay
    stateContext.reprompt = stateContext.reprompt ? []
    saySSML = joinSpeech(stateContext.say, stateContext.language)
    repromptSSML = joinSpeech(stateContext.reprompt, stateContext.language)
    if repromptSSML and saySSML
      # add spacing, if necessary
      repromptSSML += ' '

    response.reprompt =
      outputSpeech:
        type: "SSML"
        ssml: "<speak>#{repromptSSML}#{saySSML}</speak>"
  else if stateContext.reprompt? and stateContext.reprompt.length > 0
    response.reprompt =
      outputSpeech:
        type: "SSML",
        ssml: "<speak>#{joinSpeech(stateContext.reprompt, stateContext.language)}</speak>"

  if stateContext.card?
    card = stateContext.card
    title = card.title ? ""
    content = card.content ? ""
    if card.repeatSpeech and stateContext.say?
      parts = for s in stateContext.say
        stripSSML(s)
      content += parts.join('\n')
    content = content ? ""

    response.card =
      type: "Simple"
      title: title ? ""

    response.card.title = response.card.title.trim()

    if card.imageURLs?
      response.card.type = "Standard"
      response.card.text = content ? ""
      response.card.image =
        smallImageUrl: card.imageURLs.cardSmall
        largeImageUrl: card.imageURLs.cardLarge
      response.card.text = response.card.text.trim()
    else
      response.card.type = "Simple"
      response.card.content = content
      response.card.content = response.card.content.trim()

    keep = false
    keep = true if response.card.title.length > 0
    keep = true if response.card.text?.length > 0
    keep = true if response.card.content?.length > 0
    keep = true if response.card.image?.smallImageUrl?
    keep = true if response.card.image?.largeImageUrl?
    unless keep
      delete response.card


  if stateContext.musicCommand?
    stateContext.directives = stateContext.directives ? []
    switch stateContext.musicCommand.action
      when 'play'
        stateContext.directives.push
          type: "AudioPlayer.Play"
          playBehavior: "REPLACE_ALL"
          audioItem:
            stream:
              url: stateContext.musicCommand.url
              token: "no token"
              offsetInMilliseconds: 0
      when 'stop'
        stateContext.directives.push
          type: "AudioPlayer.Stop"


  # store current state for next time, unless we're intentionally ending
  if stateContext.shouldEndSession
    stateContext.currentState = null
  if stateContext.currentState == null
    response.shouldEndSession = true
  stateContext.db.write "__currentState", stateContext.currentState
  stateContext.db.write "__settings", stateContext.settings

  # filter out any directives that were marked for removal
  stateContext.directives = ( d for d in stateContext.directives when not d.DELETEME )
  if stateContext.directives? and stateContext.directives.length > 0
    response.directives = stateContext.directives

  # last chance, see if the developer left a postprocessor to run here
  if litexa.responsePostProcessor?
    litexa.responsePostProcessor wrapper, stateContext

  return await new Promise (resolve, reject) ->
    stateContext.db.finalize (err, info) ->
      if err?
        unless db.repeatHandler
          reject err
      resolve wrapper
