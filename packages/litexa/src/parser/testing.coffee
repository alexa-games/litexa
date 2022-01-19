###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

lib = {}
uuid = require 'uuid'
fs = require 'fs'
path = require 'path'

directiveValidators = {}

{ JSONValidator } = require('./jsonValidator').lib

directiveValidators['AudioPlayer.Play'] = -> []
directiveValidators['AudioPlayer.Stop'] = -> []
directiveValidators['Hint'] = -> []

validateSSML = (skill, line) ->
  errors = []
  audioCount = 0
  audioFinder = /\<\s*audio/gi
  match = audioFinder.exec line
  while match
    audioCount += 1
    match = audioFinder.exec line
  if audioCount > 5
    errors.push "more than 5 <audio/> tags in one response"
  return errors

class ParserError extends Error
  constructor: (@location, @message) ->
    super()

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
        logs.push "ERROR: " + a
        errors.push a
        if passError?
          passError a

  stop: (flush) ->
    console.log = @oldLog
    console.error = @oldError
    if flush
      console.log @logs.join('\n')


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
      new: false
    context:
      System:
        device:
          deviceId: "someDeviceId"
          supportedInterfaces: []
        user:
          userId: "amzn1.ask.account.stuff"
        application:
          applicationId: "amzn1.ask.skill.uuid"
    request : null
    version: "1.0"
  }
  device = skill.testDevice ? 'dot'
  blockedInterfaces = skill.testBlockedInterfaces ? []
  pushInterface = (interfaceName) =>
    return if interfaceName in blockedInterfaces
    req.context.System.device.supportedInterfaces[interfaceName] = {}

  switch device
    when 'dot', 'echo'
      dev = req.context.System.device
    when 'show'
      dev = req.context.System.device
      pushInterface('Display')
      pushInterface('Alexa.Presentation.APL')
      pushInterface('Alexa.Presentation.HTML')
    else
      throw new Error "Unknown test device type #{device}"

  req.__logStateTraces = skill.testLoggingTraceStates
  req.__reportStateTrace = true
  return req

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

makeLaunchRequest = (skill, time, locale) ->
  # launch requests are uniform, they just have this tacked onto the base
  req = makeBaseRequest(skill)
  req.session.new = true
  req.request =
    type: "LaunchRequest"
    requestId: makeRequestId()
    timestamp: new Date(time).toISOString()
    locale: locale
  return req

makeIntentRequest = (skill, name, slots, time, locale) ->
  # intent requests need the name and slots interpolated in
  unless skill.hasIntent name, locale
    throw "Skill does not have intent #{name}"

  req = makeBaseRequest(skill)
  req.request =
    type: "IntentRequest"
    requestId: makeRequestId()
    timestamp: new Date(time).toISOString()
    locale: locale
    intent:
      name: name
      slots: {}

  if slots?
    for name, value of slots
      req.request.intent.slots[name] = {name:name, value:value}
  return req

makeSessionEndedRequest = (skill, reason, time, locale) ->
  req = makeBaseRequest(skill)
  req.request =
    type: "SessionEndedRequest"
    requestId: makeRequestId()
    timestamp: new Date(time).toISOString()
    reason: reason
    locale: locale
    error:
      type: "string"
      message: "string"
  return req


findIntent = (skill, line) ->
  # given an expressed utterance, figure out which intent
  # it could match, and what its slots would be
  candidates = []
  for stateName, state of skill.states
    continue unless state.intents?
    for intentName, intent of state.intents
      for utterance in intent.utterances
        [score, slots] = utterance.parse line
        if slots?
          candidates.push [score, [intent, slots]]
  unless candidates.length > 0
    return [null, null]
  candidates.sort (a,b) ->
    return -1 if a[0] > b[0]
    return 1 if a[0] < b[0]
    return 0
  return candidates[0][1]


# Function that evenly left/right pads a String with a paddingChar, until targetLength is reached.
padStringWithChars = ({ str, targetLength, paddingChar }) ->
  str = str ? 'MISSING_STRING'

  numCharsPreStr = Math.max(Math.floor((targetLength - str.length) / 2), 0)
  str = "#{paddingChar.repeat(numCharsPreStr)}#{str}"

  numCharsPostStr = Math.max(targetLength - str.length, 0)
  str = "#{str}#{paddingChar.repeat(numCharsPostStr)}"

  return str


collectSays = (skill, lambda) ->
  result = []
  state = null

  collect = (part) ->
    if part.isSay
      sample = ""
      try
        sample = part.express({
          slots: {},
          lambda: lambda,
          noDatabase: true,
          language: skill.testLanguage
        })
      catch e
        console.log e
        throw new ParserError part.location, "Failed to express say `#{part}`: #{e.toString()}"
      if sample
        result.push {
          part: part
          state: state
          sample: sample
        }
    else if part.isSoundEffect
      sample = part.toSSML(skill.testLanguage)
      result.push {
        part: part
        state: state
        sample: sample
      }
    if part.startFunction?
      part.startFunction.forEachPart skill.testLanguage, collect


  for stateName, state of skill.states
    state.startFunction?.forEachPart skill.testLanguage, collect
    state.endFunction?.forEachPart skill.testLanguage, collect

    for intentName, intent of state.intents
      intent.startFunction?.forEachPart skill.testLanguage, collect

  result.sort (a, b) ->
    return -1 if a.sample.length > b.sample.length
    return 1 if a.sample.length < b.sample.length
    return 0

  return result



class lib.ExpectedExactSay
  # verbatim text match, rather than say string search
  constructor: (@location, @line) ->

  test: (skill, context, result) ->
    # compare without the say markers
    test = result.speech ? ""
    test = test.replace /\s/g, ' '

    test = abbreviateTestOutput test, context
    @line = abbreviateTestOutput @line, context

    unless @line == test
      throw new ParserError @location, "speech did not exactly match `#{@line}`"

class lib.ExpectedRegexSay
  # given a regex, rather than constructing one
  constructor: (@location, @regex) ->

  test: (skill, context, result) ->
    # compare without the say markers
    test = result.speech ? ""
    test = test.replace /\s/g, ' '

    abbreviatedTest = abbreviateTestOutput test, context
    regexp = new RegExp(@regex.expression, @regex.flags)
    unless test.match(regexp) or abbreviatedTest.match(regexp)
      throw new ParserError @location, "speech did not match regex `/#{@regex.expression}/#{@regex.flags}`"



grindSays = (language, allSays, line) ->
  # try to categorize every part of this string into
  # one of the say statements, anywhere in the skill
  ctx = {
    remainder: line
    says: []
  }

  while ctx.remainder.length > 0
    found = false
    for s in allSays
      match = s.part.matchFragment(language, ctx.remainder, true)
      if match?
        if match.offset == 0
          found = true
          ctx.remainder = match.reduced
          ctx.says.push [line.indexOf(match.removed), match.part, match.removed]
          break
    return ctx unless found
  return ctx

class lib.ExpectedSay
  # expect all say statements that concatenate into @line
  constructor: (@location, @line) ->

  test: (skill, context, result) ->
    # step 1 identify the say statements
    testLine = @line.express(context)
    collected = grindSays(skill.testLanguage, context.allSays, testLine)
    collected.remainder = collected.remainder.replace /(^[ ]+)/, ''
    collected.remainder = collected.remainder.replace /([ ]+$)/, ''
    unless collected.remainder.length == 0
      throw new ParserError @location, "no say statements match `#{collected.remainder}` out of
        `#{testLine}`"

    # step 2, check to see that the response can
    # match each say, in order
    remainder = result.speech
    remainder = abbreviateTestOutput remainder, context
    for sayInfo, sayIndex in collected.says
      match = sayInfo[1].matchFragment(skill.testLanguage, remainder, true)
      unless match?
        throw new ParserError @location, "failed to match expected segment #{sayIndex}
          `#{sayInfo[2]}`, seeing `#{remainder}` instead"
      unless match.offset == 0
        throw new ParserError @location, "say statement appeared out of order `#{match.removed}`"
      remainder = match.reduced

    unless remainder.length == 0
      throw new ParserError @location, "unexpected extra speech, `#{remainder}`"


class lib.ExpectedState
  # expect the state in the response to be @name
  constructor: (@location, @name) ->

  test: (skill, context, result) ->
    data = context.db.getVariables(makeHandlerIdentity(skill))
    if @name == 'null'
      unless data.__currentState == null
        throw new ParserError @location, "response was in state `#{data.__currentState}` instead of
          expected empty null state"
      return

    unless @name of skill.states
      throw new ParserError @location, "test specifies unknown state `#{@name}`"

    unless data.__currentState == @name
      throw new ParserError @location, "response was in state `#{data.__currentState}` instead of
        expected `#{@name}`"


comparatorNames = {
  "==": "equal to"
  "!=": "unequal to"
  ">=": "greater than equal to"
  "<=": "less than or equal to"
  ">": "greater than"
  "<": "less than"
}

class lib.ExpectedDB
  # expect the value in the db to be this
  constructor: (@location, @reference, @op, @tail) ->

  test: (skill, context, result) ->
    data = context.db.getVariables(makeHandlerIdentity(skill))
    value = @reference.readFrom(data)
    unless value?
      throw new ParserError @location, "db value `#{@reference}` didn't exist"
    tail = JSON.stringify(eval(@tail))
    unless eval("value #{@op} #{tail}")
      value = JSON.stringify(value)
      throw new ParserError @location, "db value `#{@reference}` was `#{value}`, not
        #{comparatorNames[@op]} `#{tail}`"


class lib.ExpectedEndSession
  # expect the response to indicate the session should end
  constructor: (@location) ->

  isExpectedEndSession: true

  test: (skill, context, result) ->
    unless result.data.response.shouldEndSession
      throw new ParserError @location, "session did not indicate it should end as expected"

class lib.ExpectedContinueSession
  constructor: (@location, @kinds) ->

  isExpectedContinueSession: true

  test: (skill, context, result) ->
    if 'microphone' in @kinds
      unless result.data.response.shouldEndSession == false
        throw new ParserError @location, "skill is not listening for microphone"
    else
      if result.data.response.shouldEndSession?
        throw new ParserError @location, "skill is not listening for events, without microphone"

class lib.ExpectedDirective
  # expect the response to indicate the session should end
  constructor: (@location, @name) ->

  isExpectedDirective: true

  test: (skill, context, result) ->
    unless result.data.response.directives?
      throw new ParserError @location, "response did not contain any directives, expected #{@name}"
    found = false
    for directive in result.data.response.directives
      if directive.type == @name
        found = true
        break
    unless found
      types = ( d.type for d in result.data.response.directives )
      throw new ParserError @location, "response did not contain expected directive #{@name}, instead had [#{types}]"


class lib.ResponseGeneratingStep
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

  processEvent: ({ result, skill, lambda, context, resultCallback }) ->
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
            expectation.test(skill, context, result)
          catch ex
            result.errors.push ex.message
            result.expectationsMet = false

        result.logs.push l for l in trap.logs
        result.errors.push e for e in trap.errors
        result.shouldEndSession = result.data?.response?.shouldEndSession
        resultCallback null, result

    catch ex
      result.err = ex
      if trap?
        trap.stop(true)
        result.logs.push l for l in trap.logs
        result.errors.push e for e in trap.errors
      resultCallback ex, result

class RequestStep extends lib.ResponseGeneratingStep
  constructor: (@location, @requestType, @source) ->
    super()

  isVoiceStep: true

  run: ({ skill, lambda, context, resultCallback }) ->
    result = @makeResult()
    context.attributes = {}

    event = makeBaseRequest( skill )

    if @requestType
      # support for just generating an empty request with a given type
      event.request = { type: @requestType }

    if @source?
      # support for loading a request from a file
      unless skill.files[@source]
        return resultCallback new ParserError @location, "couldn't find file #{@source} for this request"
      event.request = skill.files[@source].contentForLanguage('default')

    # try to fish out an intent name for the test report
    # if there is one, otherwise show the request type
    result.intent = event.request.intent?.name ? event.request.type

    result.event = event
    @processEvent { result, skill, lambda, context, resultCallback }

class LaunchStep extends lib.ResponseGeneratingStep
  constructor: (@location, @say, @intent) ->
    super()

  isVoiceStep: true

  run: ({ skill, lambda, context, resultCallback }) ->
    result = @makeResult()
    context.attributes = {}
    result.intent = "LaunchRequest"
    event = makeLaunchRequest( skill, context.time, skill.testLanguage )
    result.event = event
    @processEvent { result, skill, lambda, context, resultCallback }

class VoiceStep extends lib.ResponseGeneratingStep
  constructor: (@location, @say, @intent, values) ->
    super()
    @values = {}
    if values?
      # the parser gives this to use an array of k/v pair arrays
      for v in values
        @values[v[0]] = { value:v[1] }
    if @say?.alternates?.default?
      for alt in @say.alternates.default
        for part, i in alt
          if part?.isSlot
            unless part.name of @values
              throw new ParserError @location, "test say statements has
                named slot $#{part.name}, but no value for it"
            part.fixedValue = @values[part.name].value
            @values[part.name].found = true
      for k, v of @values
        unless v.found
          throw new ParserError @location, "test say statement specifies
            value for unknown slot #{k}"

  isVoiceStep: true

  run: ({ skill, lambda, context, resultCallback }) ->
    result = @makeResult()
    if @intent?
      result.intent = @intent
      result.slots = {}
      for k, v of @values
        result.slots[k] = v.value
      event = makeIntentRequest( skill, @intent, result.slots, context.time, skill.testLanguage )
    else if @say?
      result.expressed = @say.express(context)
      [intent, slots] = findIntent(skill, result.expressed)
      for name, value of slots
        if name of @values
          slots[name] = @values[name].value
      unless intent?
        resultCallback new Error("couldn't match `#{result.expressed}` to any intents")
        return
      result.intent = intent.name
      result.slots = slots
      event = makeIntentRequest( skill, intent.name, slots, context.time, skill.testLanguage )
    else
      resultCallback new Error("Voice step has neither say nor intent")
      return

    result.event = event
    @processEvent { result, skill, lambda, context, resultCallback }


class DBFixupStep
  constructor: (@reference, @code) ->

  isDBFixupStep: true

  run: ({ skill, lambda, context, resultCallback }) ->
    try
      identity = makeHandlerIdentity(skill)
      data = context.db.getVariables(identity)
      @reference.evalTo(data, @code)
      context.db.setVariables(identity, data)
      resultCallback null, {}
    catch err
      resultCallback err, {}


class WaitStep
  constructor: (@duration) ->

  isWaitStep: true

  run: ({ skill, lambda, context, resultCallback }) ->
    context.time += @duration
    context.alreadyWaited = true
    resultCallback null, {}

class StopStep
  constructor: (@reason) ->
    @requestReason = switch @reason
      when 'quit' then 'USER_INITIATED'
      when 'drop' then 'EXCEEDED_MAX_REPROMPTS'
      else 'USER_INITIATED'

  isStopStep: true

  run: ({ skill, lambda, context, resultCallback }) ->
    try
      event = makeSessionEndedRequest( skill, @requestReason, context.time, skill.testLanguage )
      lambda.handler event, {}, (err, data) =>
        resultCallback err, data
    catch err
      resultCallback err, {}

class SetRegionStep
  constructor: (@region) ->
  run: ({ skill, lambda, context, resultCallback }) ->
    skill.testLanguage = @region
    resultCallback null, {}
  report: ({ err, logs, sourceLine, step, output, result, context }) ->
    logs.push "setting region to #{step.region}"


class SetLogStateTraces
  constructor: (@location, @value) ->
  run: ({ skill, lambda, context, resultCallback }) ->
    skill.testLoggingTraceStates = @value
    resultCallback null, {}
  report: ({ err, logs, sourceLine, step, output, result, context }) ->
    if @value
      logs.push "enabling state tracing"
    else
      logs.push "disabling state tracing"


class CaptureStateStep
  constructor: (@location, @name) ->
  run: ({ skill, lambda, context, resultCallback }) ->
    context.captures[@name] =
      db: context.db.getVariables(makeHandlerIdentity(skill))
      attr: JSON.stringify(context.attributes)
    resultCallback null, {}
  report: ({ err, logs, sourceLine, step, output, result, context }) ->
    logs.push "#{sourceLine} captured state as '#{@name}'"

class ResumeStateStep
  constructor: (@location, @name) ->
  run: ({ skill, lambda, context, resultCallback }) ->
    unless @name of context.captures
      throw new ParserError @location, "No state named #{@name} to resume here"
    state = context.captures[@name]
    context.db.setVariables(makeHandlerIdentity(skill),state.db)
    context.attributes = JSON.parse state.attr
    resultCallback null, {}
  report: ({ err, logs, sourceLine, step, output, result, context }) ->
    logs.push "#{sourceLine} resumed from state '#{@name}'"


validateDirective = (directive, context) ->
  validatorFunction = directiveValidators[directive?.type]

  unless validatorFunction?
    # no? Try the ones from any loaded extensions
    validatorFunction = context.skill.directiveValidators[directive?.type]

  unless validatorFunction?
    if context.skill.projectInfo?.directiveWhitelist?
      return null if directive?.type in context.skill.projectInfo?.directiveWhitelist
    if context.skill.projectInfo?.validDirectivesList?
      return null if directive?.type in context.skill.projectInfo?.validDirectivesList
    return [ "unknown directive type #{directive?.type}" ]
  try
    validator = new JSONValidator directive
    validatorFunction(validator)
    if validator.errors.length > 0
      return ( e.toString() for e in validator.errors )
  catch e
    return [ e.toString() ]
  return null


abbreviateTestOutput = (line, context) ->
  return null unless line?
  # shorten audio
  cleanedBucket = context.testContext.litexa?.assetsRoot ? ''
  cleanedBucket += context.testContext.language + "/"
  cleanedBucket = cleanedBucket.replace /\-/gi, '\\-'
  cleanedBucket = cleanedBucket.replace /\./gi, '\\.'
  cleanedBucket = cleanedBucket.replace /\//gi, '\\/'

  # audio src=
  audioFinderRegex = "<audio\\s+src='#{cleanedBucket}([\\w\\/\\-_\\.]*)\\.mp3'/>"
  line = abbreviateRegexReplacer line, audioFinderRegex, "<", ".mp3>"

  # SFX URLs/soundbanks
  audioUrlFinderRegex = "<audio\\s+src=['\"]([a-zA-Z0-9_\\-\\.\\/\\:]*)['\"]/>"
  line = abbreviateRegexReplacer line, audioUrlFinderRegex

  # SFX shorthand
  sfxUrlFinderRegex = "<sfx\\s+['\"]?([a-zA-Z0-9_\\-\\.\\/\\:]*)['\"]?>"
  line = abbreviateRegexReplacer line, sfxUrlFinderRegex

  # also interjections
  interjectionFinderRegex = "<say-as.interpret-as='interjection'>([^<]*)<\\/say-as>"
  line = abbreviateRegexReplacer line, interjectionFinderRegex, "<!"

  # also breaks
  breakFinderRegex = "<break.time='(([0-9]+)((s)|(ms)))'\\/>"
  line = abbreviateRegexReplacer line, breakFinderRegex, "<..."

  # clean up any white space oddities
  line = line.replace /\s/g, ' '
  return line


abbreviateRegexReplacer = (line, regex, matchPrefix = '<', matchSuffix = '>') ->
  regex = new RegExp regex, 'i'
  match = regex.exec line

  while match?
    line = line.replace match[0], "#{matchPrefix}#{match[1]}#{matchSuffix}"
    match = regex.exec line

  return line


functionStripper = /function\s*\(\s*\)\s*{\s*return\s*([^}]+);\n\s*}$\s*$/

class TestLibrary
  constructor: (@target, @testContext) ->
    @counter = 0

  error: (message) ->
    throw new Error "[#{@counter}] "  + message
  equal: (a, b) ->
    @counter += 1
    unless a == b
      @error "#{a} didn't equal #{b}"
  check: (condition) ->
    @counter += 1
    result = condition()
    unless result
      match = functionStripper.exec condition.toString()
      @error "false on #{match?[1] ? condition}"
  report: (message) ->
    if typeof(message) != 'string'
      message = JSON.stringify(message)
    @target.messages.push "  t! #{message}"
  warning: (message) ->
    if typeof(message) != 'string'
      message = JSON.stringify(message)
    @target.messages.push " t✘! #{message}"
  expect: (name, condition) ->
    startLine = @target.messages.length
    @counter = 0
    try
      doTest = true
      if @target.filters
        doTest = false
        for f in @target.filters
          if name.indexOf(f) >= 0
            doTest = true
      if doTest
        condition()
        @target.reportTestCase null, name, startLine
    catch err
      @target.reportTestCase err, name, startLine
  directives: (title, directives) ->
    @counter += 1
    unless Array.isArray(directives)
      directives = [directives]
    failed = false
    for d, idx in directives
      report = validateDirective d, @testContext
      continue if report == null
      if report.length == 1
        failed = true
        @target.messages.push "  ✘ #{title}[#{idx}]: #{report[0]}"
      else if report.length > 1
        failed = true
        @target.messages.push "  ✘ #{title}[#{idx}]"
        for r in report
          @target.messages.push "     ✘ #{r}"
    unless failed
      @report "#{title} OK"


class lib.CodeTest
  constructor: (@file) ->

  test: (testContext, output, resultCallback) ->
    { skill, db, lambda } = testContext
    Test = new TestLibrary @, testContext
    @messages = []
    @successes = 0
    @failures = 0
    Test.target = @
    exception = @file.exception

    catchLog = (str) => @messages.push "  c! " + str
    catchError = (str) => @messages.push " c✘! " + str
    trap = new TrapLog catchLog, catchError

    @testCode = null
    fileCode = null
    unless exception?
      try
        fileCode = @file.contentForLanguage(skill.testLanguage)

        localTestRootFormatted = skill.projectInfo.testRoot.replace(/\\/g, '/')
        localAssetsRootFormatted = path.join(testContext.litexaRoot, 'assets').replace(/\\/g, '/')
        modulesRootFormatted = path.join(testContext.litexaRoot).replace(/\\/g, '/')
        @testCode = [
          """
            exports.litexa = {
              assetsRoot: 'test://',
              localTesting: true,
              localTestRoot: '#{localTestRootFormatted}',
              localAssetsRoot: '#{localAssetsRootFormatted}',
              modulesRoot: '#{modulesRootFormatted}'
            };
          """
          skill.libraryCode
          skill.testLibraryCodeForLanguage(skill.testLanguage)
          "initializeExtensionObjects({})"
          fileCode.js ? fileCode
        ].join('\n')
        fs.writeFileSync path.join(testContext.testRoot, @file.name + '.log'), @testCode, 'utf8'
        eval @testCode
      catch e
        exception = e
    trap.stop(false)

    if exception?
      output.log.push "✘ code test: #{@file.name}, failed"
      location = ''
      if exception.location?
        l = exception.location
        location = "[#{l.first_line}:#{l.first_column}] "
      else if exception.stack
        match = (/at eval \((.*)\)/i).exec exception.stack
        location = "[#{match[1]}] " if match
      output.log.push "  ✘ #{location}#{exception.message ? ("" + exception)}"
      output.log.push " c!: #{l}" for l in trap.logs
      resultCallback @file.exception, false
    else
      if @failures == 0
        if @successes > 0
          @messages.unshift "✔ #{@file.filename()}, #{@successes} tests passed"
      else
        @messages.unshift "✘ #{@file.filename()}, #{@failures} tests failed, #{@successes} passed"

      if @messages.length > 0
        output.log.push @messages.join('\n')

      resultCallback null, @successes, @failures

  reportTestCase: (err, name, startLine) ->
    startLine = startLine ? @messages.length
    if err?
      @failures += 1
      @messages.splice startLine, 0, "  ✘ #{@file.filename()} '#{name}': #{err.message}"
    else
      @successes += 1
      @messages.splice startLine, 0, "  ✔ #{@file.filename()} '#{name}'"
    @messages.push ''


class lib.TestContext
  constructor: (@skill, @options) ->
    @output =
      log: []
      cards: []
      directives: []

  collectAllSays: ->
    @allSays = collectSays @skill, @lambda


class lib.Test
  constructor: (@location, @name, @sourceFilename) ->
    @steps = []
    @capturesNames = []
    @resumesNames = []

  isTest: true

  pushUser: (location, line, intent, slots) ->
    if line? or intent?
      @steps.push new VoiceStep(location, line, intent, slots)
    else
      @steps.push new LaunchStep(location)

  pushRequest: (location, name, source) ->
    @steps.push new RequestStep(location, name, source)

  pushTestStep: (step) ->
    @steps.push step

  pushExpectation: (obj) ->
    end = @steps.length - 1
    for i in [end..0] by -1
      if @steps[i].pushExpectation?
        @steps[i].pushExpectation(obj)
        return
    throw new ParserError obj.location, "alexa test expectation pushed without prior intent"

  findLastStep: (predicate) ->
    return null if @steps.length <= 0
    for i in [@steps.length-1..0]
      if predicate(@steps[i])
        return @steps[i]
    return null

  pushDatabaseFix: (name, code) ->
    @steps.push new DBFixupStep(name, code)

  pushWait: (duration) ->
    @steps.push new WaitStep(duration)

  pushStop: (reason) ->
    @steps.push new StopStep(reason)

  pushSetRegion: (region) ->
    @steps.push new SetRegionStep(region)

  pushCaptureNamedState: (location, name) ->
    @steps.push new CaptureStateStep(location, name)
    @capturesNames.push name

  pushResumeNamedState: (location, name) ->
    @steps.push new ResumeStateStep(location, name)
    @resumesNames.push name

  pushSetLogStateTraces: (location, value) ->
    @steps.push new SetLogStateTraces(location, value)

  reportEndpointResponses: ({ result, context, output, logs }) ->
    success = true
    skill = context.skill

    rawObject =
      ref: logs?[logs.length - 1]
      request: result?.event ? {}
      response: result?.data ? {}
      db: context.db.getVariables(makeHandlerIdentity(skill))
      trace: result?.data?.__stateTrace

    # filter out test control items
    for obj in [rawObject.response, rawObject.request]
      for k of obj
        if k[0] == '_'
          delete obj[k]

    # If turned on via test options, this logs all raw responses/requests and DB contents.
    # @TODO: For extensive tests, dumping this raw object aborts with a JS Heap OOM error
    # (during writeFileSync in test.coffee) -> should be addressed.
    if context.testContext.options?.logRawData?
      output.raw.push rawObject

    if result.err
      rawObject.error = result.err.stack ? '' + result.err
      logs.push "   ✘ handler error: #{result.err}"
      if result.err.stack?
        stack = '' + result.err.stack
        lines = stack.split '\n'
        for l in lines
          l = l.replace /\([^\)]*\)/g, ''
          logs.push "     #{l}"
          if l.indexOf('processIntents') >= 0
            break
      success = false
    else if result.event
      stateName = ""
      for ident, vars of context.db.identities
        stateName = vars['__currentState']
      state = "◖#{padStringWithChars({
        str: stateName ? ''
        targetLength: skill.maxStateNameLength
        paddingChar: '-'
      })}◗"

      if skill.abbreviateTestOutput
        speech = abbreviateTestOutput( result.speech, context )
        reprompt = abbreviateTestOutput( result.reprompt, context )
      else
        speech = result.speech
        reprompt = result.reprompt

      speech = speech.replace /"/g, '❝' if speech?
      reprompt = reprompt.replace /"/g, '❝' if reprompt?

      if speech?
        speech = "\"#{speech}\""
      else
        speech = "NO SPEECH"

      if reprompt?
        reprompt = "\"#{reprompt}\""
      else
        reprompt = "NO REPROMPT"

      if result.expectationsMet
        logs.push "     #{state} #{speech} ... #{reprompt}"
      else
        logs.push "   ✘ #{state} #{speech} ... #{reprompt}"
        success = false

      do =>
        check = (key) =>
          errors = validateSSML skill, result[key]
          if errors.length > 0
            success = false
            for error in errors
              logs.push "      ✘ #{key}: #{error}"
        check 'speech'
        check 'reprompt'

      if result.card?
        index = output.cards.length
        output.cards.push result.card
        logs.push "      [CARD #{index}] #{result.cardReference}"

      if result.directives?
        for directive in result.directives
          index = output.directives.length
          output.directives.push directive
          if directive? && context.skill.directiveFormatters[directive?.type]?
            lines = context.skill.directiveFormatters[directive?.type](directive)
            if Array.isArray(lines) 
              for line in lines 
                logs.push "      #{line}"
            else 
                logs.push "      #{lines}"
          else
            logs.push "      [DIRECTIVE #{index}] #{directive?.type}"
          validationErrors = validateDirective(directive, context)
          if validationErrors
            for error in validationErrors
              logs.push "      ✘ #{error}"
            success = false

      if result.shouldEndSession
        logs.push "  ◣  Voice session ended"

    if result.errors?
      for e in result.errors
        logs.push "     ✘ #{e}"

    if result.logs?
      for l in result.logs
        logs.push "     ! #{l}"

    return success

  test: (testContext, output, resultCallback) ->
    { skill, db, lambda } = testContext
    logs = []
    db.captures = db.captures ? {}

    context =
      db: db
      attributes: {}
      allSays: collectSays(skill, lambda)
      lambda: lambda
      skill: skill
      captures: db.captures
      testContext: testContext

    # reset this for each test
    skill.testBlockedInterfaces = [];

    success = true

    gap = (" " for i in [0...skill.maxStateNameLength+2]).join('')

    skill.testLoggingTraceStates = false

    remainingSteps = ( s for s in @steps )
    nextStep = =>
      ###
      if db.db.variables != context.db
        db.db.variables = context.db
        db.db.initialized = true
      ###

      if remainingSteps.length == 0
        unless testContext.options.singleStep
          if success
            logs.unshift "✔ test: #{@name}"
          else
            logs.unshift "✘ test: #{@name}"
        output.log.push logs.join('\n')
        successCount = 0
        failCount = 0
        failedTestName = undefined
        if success
          successCount = 1
        else
          failCount = 1
          failedTestName = @name
        setTimeout (->resultCallback null, successCount, failCount, failedTestName), 1
        return

      step = remainingSteps.shift()

      unless context.time?
        # first time in here, we'll initialize to a fixed point in time
        context.time = (new Date(2017, 9, 1, 15, 0, 0)).getTime()

      if step.isVoiceStep or step.testingTimeIncrement
        # unless we had an explicit wait from the test script,
        # we'll insert a few seconds between every user event
        unless context.alreadyWaited
          context.time += step.testingTimeIncrement ? 65 * 1000
          context.alreadyWaited = false

      step.run { skill, lambda, context, resultCallback: (err, result) =>
        if err? or result?.err?
          success = false

        sourceLine = step.location?.start?.line ? "--"
        sourceLine += "."

        switch
          when step.isStopStep
            if err
              logs.push "     ✘ processed #{step.requestReason} session end with error: #{err}"
            else
              logs.push "     • processed #{step.requestReason} session end without errors"

          when step.isDBFixupStep
            if err
              logs.push "     ✘ db fixup error: @#{step.reference}, #{err}"
            else
              logs.push "     • db fixup @#{step.reference}"

          when step.isWaitStep
            minutes = step.duration / 1000 / 60
            logs.push "     • waited #{minutes.toFixed(2)} minutes"

          when step.isVoiceStep
            if err
              logs.push "#{sourceLine}  ❢ Voice intent error: #{err}"
            else
              result = result ? {}
              time = (new Date(context.time)).toLocaleTimeString()

              textSlots = ""
              if result.slots?
                textSlots = ( "$#{k}=#{v}" for k, v of result.slots ).join(', ')

              if result.intent?
                paddedIntent = result.intent[0...skill.maxStateNameLength+2]
              else
                paddedIntent = "ERROR"
              paddedIntent = padStringWithChars({
                str: paddedIntent
                targetLength: skill.maxStateNameLength + 2
                paddingChar: ' '
              })

              input = ""
              #input = "\"#{result.expressed ? step.intent ? "launch"}\" -- "
              logs.push "#{sourceLine}  ❢ #{paddedIntent} #{input}#{textSlots} @ #{time}"

            if result?
              unless @reportEndpointResponses { result, context, output, logs }
                success = false

          when step.report?
            step.report({ err, logs, sourceLine, step, output, result, context })

            if result?
              unless @reportEndpointResponses { result, context, output, logs }
                success = false

          else
            throw new Error "unexpected step"

        nextStep()
      }

    nextStep()

lib.TestUtils = {
  makeBaseRequest
  makeHandlerIdentity
  makeRequestId
  padStringWithChars
}

module.exports = {
  lib
}
