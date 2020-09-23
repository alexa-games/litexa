###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

lib = module.exports.lib = {}

{ Function } = require('./function.coffee').lib
{ Intent, FilteredIntent } = require('./intent.coffee').lib
{ ParserError } = require("./errors.coffee").lib

class lib.Transition
  constructor: (@name, @stop) ->

  toLambda: (output, indent, options) ->
    output.push "#{indent}context.nextState = '#{@name}';"
    if @stop
      output.push "#{indent}context.handoffState = '#{@name}';"
      output.push "#{indent}context.handoffIntent = true;"
      output.push "#{indent}return;"

  validateStateTransitions: (allStateNames) ->
    unless @name in allStateNames
      throw new ParserError @location, "Transition to non existant state: #{@name}"

class lib.HandoffIntent
  constructor: (@name) ->

  toLambda: (output, indent, options) ->
    output.push "#{indent}context.handoffState = '#{@name}';"
    output.push "#{indent}context.handoffIntent = true;"

  validateStateTransitions: (allStateNames) ->
    unless @name in allStateNames
      throw new ParserError @location, "Handoff to non existant state: #{@name}"

class lib.SetSkillEnd
  constructor: ->

  toLambda: (output, indent, options) ->
    output.push "#{indent}context.shouldEndSession = true;"

class lib.SetSkillListen
  constructor: (@kinds) ->

  toLambda: (output, indent, options) ->
    output.push "#{indent}context.shouldEndSession = false;"
    unless 'microphone' in @kinds
      output.push "#{indent}context.shouldDropSession = true;"


class lib.LogMessage
  constructor: (@contents) ->

  toLambda: (output, indent, options) ->
    output.push "#{indent}exports.Logging.log(JSON.stringify(#{@contents.toLambda(options)}));"


class lib.State
  constructor: (@name) ->
    @intents = {}
    @languages = {}
    @parsePhase = 'start'
    @pushOrGetIntent null, '--default--', null
    @parsePhase = 'start'
    @locations = { default: null }

  isState: true

  prepareForLanguage: (location) ->
    return unless location?.language
    return if location.language == 'default'
    unless location.language of @languages
      @languages[location.language] = {}

  resetParsePhase: ->
    # used by the default constructors, pre parser
    @parsePhase = 'start'

  collectDefinedSlotTypes: (context, customSlotTypes) ->
    workingIntents = @collectIntentsForLanguage(context.language)
    for name, intent of workingIntents
      intent.collectDefinedSlotTypes context, customSlotTypes

  validateSlotTypes: (context, customSlotTypes) ->
    workingIntents = @collectIntentsForLanguage(context.language)
    for name, intent of workingIntents
      intent.validateSlotTypes customSlotTypes

  validateTransitions: (allStateNames, language) ->
    @startFunction?.validateStateTransitions(allStateNames, language)
    for name, intent of @intents
      intent.validateStateTransitions allStateNames, language
    for name, intent of @languages[language]
      intent.validateStateTransitions allStateNames, language

  hasIntent: (name, language) ->
    workingIntents = @collectIntentsForLanguage language
    for intentName, intent of workingIntents
      return true if name == intentName

    return false

  reportIntents: (language, output) ->
    workingIntents = @collectIntentsForLanguage language
    for name, intent of workingIntents
      continue if name == '--default--'
      report = intent.report()
      output[report] = true

  getIntentInLanguage: (language, intentName) ->
    if language == 'default'
      return @intents[intentName]
    return @languages[language]?[intentName]

  pushOrGetIntent: (location, utterance, intentInfo) ->
    switch @parsePhase
      when 'start'
        @parsePhase = 'intents'
      when 'intents'
        # fine
      else
        throw new ParserError location, "cannot add a new intent handler to the state `#{@name}` at
          this location. Have you already added state exit code before here? Check your indentation."
    try
      key = Intent.utteranceToName(location, utterance)
    catch err
      throw new ParserError location, "Cannot create intent name from `#{utterance}`: #{err}"
    language = location?.language ? 'default'
    collection = @intents

    if language != 'default'
      @languages[language] = @languages[language] ? {}
      collection = @languages[language]
    unless key of collection
      if intentInfo?.class?
        collection[key] = new intentInfo.class({ location, utterance })
      else
        collection[key] = new Intent({ location, utterance })
    else if !collection[key].defaultedResetOnGet and key != '--default--'
      # only allow repeat intents if they are events that can be filtered
      if collection[key] not instanceof FilteredIntent
        throw new ParserError location, "Not allowed to redefine intent `#{key}` in state `#{@name}`"

    intent = collection[key]

    if intent.defaultedResetOnGet
      intent.resetCode()
      intent.defaultedResetOnGet = undefined

    intent.allLocations.push location
    return intent

  pushCode: (line) ->
    switch @parsePhase
      when 'start'
        @startFunction = @startFunction ? new Function
        @startFunction.pushLine(line)
      when 'end', 'intents'
        @endFunction = @endFunction ? new Function
        @endFunction.pushLine(line)
        @parsePhase = 'end'
      else
        throw new ParserError line.location, "cannot add code to the state `#{@name}` here, you've already begun defining intents"

  collectIntentsForLanguage: (language) ->
    workingIntents = {}
    # for a given state, you will get the intents in that locale's
    # version of that state only (intents are not inherited from the parent state)
    if language of @languages
      for name, intent of @languages[language]
        workingIntents[name] = intent
      if @name == 'global'
        unless '--default--' of workingIntents
          workingIntents['--default--'] = @intents['--default--']
    else if @intents?
      for name, intent of @intents
        workingIntents[name] = intent
    return workingIntents

  toLambda: (output, options) ->
    workingIntents = @collectIntentsForLanguage(options.language)

    options.scopeManager = new (require('./variableScope').VariableScopeManager)(@locations[options.language], @name)
    options.scopeManager.currentScope.referenceTester = options.referenceTester

    enterFunc = []
    @startFunction?.toLambda(enterFunc, "", options)

    exitFunc = []
    if @endFunction?
      @endFunction.toLambda(exitFunc, "", options)

    childIntentsEncountered = []
    intentsFunc = []
    intentsFunc.push "switch( context.intent ) {"
    for name, intent of workingIntents
      options.scopeManager.pushScope intent.location, "intent:#{name}"
      if name == '--default--'
        intentsFunc.push "  default: {"

        if @name == 'global'
          intentsFunc.push "    if (!runOtherwise) { return false; }"

        if @name != 'global'
          intentsFunc.push "    if ( await processIntents.global(context, #{not intent.hasContent}) ) { return true; }"
          if intent.hasContent
            intent.toLambda(intentsFunc, options)
        else if intent.hasContent
            intent.toLambda(intentsFunc, options)
        else
          if options.strictMode
            intentsFunc.push "    throw new Error('unhandled intent ' + context.intent + ' in state ' + context.handoffState);"
          else
            intentsFunc.push "    console.error('unhandled intent ' + context.intent + ' in state ' + context.handoffState);"
      else
        # Child intents are registered to the state as handlers, but it is parent handlers that perform the logic
        # of adding them to the same switch case. Therefore, keep track of the ones already added to transformed code and
        # ignore them if they are encountered again.
        if childIntentsEncountered.includes intent.name
          options.scopeManager.popScope()
          continue

        for intentName in intent.childIntents
          intentsFunc.push "  case '#{intentName}':"
          childIntentsEncountered.push intentName

        intentsFunc.push "  case '#{intent.name}': {"

        if intent.code?
          for line in intent.code.split('\n')
            intentsFunc.push "    " + line
        else
          intent.toLambda(intentsFunc, options)
      intentsFunc.push "    break;\n    }"
      options.scopeManager.popScope()
    intentsFunc.push "}"

    unless options.scopeManager.depth() == 1
      throw new ParserError @locations[options.language], "scope imbalance: returned to state but
        scope has #{options.scopeManager.depth()} depth"

    # if we have local variables in the root scope that are accessed
    # after the enter function, then we need to persist those to the
    # database in a special state scope
    rootScope = options.scopeManager.currentScope
    if rootScope.hasDescendantAccess()
      names = []

      # collect names
      for k, v of rootScope.variables when v.accesedByDescendant
        names.push k

      # unpack into local variables at the start of handlers, except
      # for the entry handler where they're initialized
      unpacker = "let {#{names.join ', '}} = context.db.read('__stateLocals') || {};"
      intentsFunc.unshift unpacker
      exitFunc.unshift unpacker

      # pack into database object and the end of handlers, except
      # for the exit state, where they're forgotten
      packer = "context.db.write('__stateLocals', {#{names.join ', '}} );"
      enterFunc.push packer
      intentsFunc.push packer


    output.push "enterState.#{@name} = async function(context) {"
    output.push "  " + e for e in enterFunc
    output.push "};"

    intentsFunc.push "return true;"
    output.push "processIntents.#{@name} = async function(context, runOtherwise) {"
    output.push "  " + e for e in intentsFunc
    output.push "};"

    output.push "exitState.#{@name} = async function(context) {"
    output.push "  " + e for e in exitFunc
    output.push "};"

    output.push ""

  hasStatementsOfType: (types) ->
    if @startFunction?
      return true if @startFunction.hasStatementsOfType(types)
    if @intents?
      for name, intent of @intents
        return true if intent.hasStatementsOfType(types)
    return false

  collectRequiredAPIs: (apis) ->
    @startFunction?.collectRequiredAPIs(apis)
    @endFunction?.collectRequiredAPIs(apis)
    if @intents?
      for name, intent of @intents
        intent.collectRequiredAPIs apis

  toUtterances: (output) ->
    workingIntents = @collectIntentsForLanguage(output.language)
    for name, intent of workingIntents
      continue if intent.referenceIntent?
      intent.toUtterances(output)

  toModelV2: (output, context, extendedEventNames) ->
    workingIntents = @collectIntentsForLanguage(context.language)
    for name, intent of workingIntents
      continue if name == '--default--'
      continue if intent.referenceIntent?
      unless intent.hasUtterances
        unless context.skill.testDevice? and (name in extendedEventNames or name.includes('.')) # supported events have '.' in their names
          console.warn "`#{name}` does not have utterances; not adding to language model."
        continue
      try
        model = intent.toModelV2(context)
      catch err
        if err.location
          throw err # ParserErrors have location properties; propagate the error
        else 
          throw new Error "failed to write language model for state `#{@name}`: #{err}"

      continue unless model?

      if model.name of context.intents
        console.error "duplicate `#{model.name}` intent found while writing model"
      else
        context.intents[model.name] = model
        output.languageModel.intents.push model

  toLocalization: (localization) ->
    @startFunction?.toLocalization(localization)

    for name, intent of @intents
      if !localization.intents[name]? and name != '--default--' # 'otherwise' handler -> no utterances
        # if this is a new intent, add it to the localization map
        localization.intents[name] = { default: [] }

      # add utterances mapped to the intent, and speech lines in the intent handler
      intent.toLocalization(localization)
