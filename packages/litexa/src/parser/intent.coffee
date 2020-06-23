###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

lib = module.exports.lib = {}

{ Function, FunctionMap } = require("./function.coffee").lib
{ Slot } = require("./utterance.coffee").lib
{ ParserError, formatLocationStart } = require("./errors.coffee").lib
{ Utterance } = require('./utterance.coffee').lib
Utils = require('@src/parser/utils').lib


builtInIntents = [
  "AMAZON.CancelIntent"
  "AMAZON.FallbackIntent"
  "AMAZON.HelpIntent"
  "AMAZON.MoreIntent"
  "AMAZON.NavigateHomeIntent"
  "AMAZON.NavigateSettingsIntent"
  "AMAZON.NextIntent"
  "AMAZON.NoIntent"
  "AMAZON.PageDownIntent"
  "AMAZON.PageUpIntent"
  "AMAZON.PauseIntent"
  "AMAZON.PreviousIntent"
  "AMAZON.RepeatIntent"
  "AMAZON.ResumeIntent"
  "AMAZON.ScrollDownIntent"
  "AMAZON.ScrollLeftIntent"
  "AMAZON.ScrollRightIntent"
  "AMAZON.ScrollUpIntent"
  "AMAZON.StartOverIntent"
  "AMAZON.StopIntent"
  "AMAZON.YesIntent"
]

builtInSlotTypes = [
  "AMAZON.NUMBER"
]

builtInReference = {}

do ->
  for b in builtInIntents
    parts = b.split('.')
    key = parts.shift()
    unless key of builtInReference
      builtInReference[key] = {}
    builtInReference[key][parts] = true


identifierFromString = (location, str) ->
  # no spaces
  str = str.replace /\s+/g, '_'
  # no casing
  str = str.toUpperCase()
  # replace numbers with a placeholder token
  str = str.replace /[0-9]/g, 'n'
  # dump everything else
  str = str.replace /[^A-Za-z_.]/g, ''
  # no consecutive underscores or periods
  str = str.replace /_+/g, '_'
  str = str.replace /\.+/g, '_'
  if str.length == 0 or str == '_'
    throw new ParserError location, "utterance reduces to unsuitable intent name `#{str}`.
      You may need to use an explicit intent name instead?"
  # must start with a letter
  unless str[0].match /[A-Za-z]/
    str = 'i' + str
  str




class lib.Intent
  # Use a static index to track instances of { utterance: { intentName, location } },
  # so we can check for identical utterances being ambiguously handled by different intents.
  @allUtterances: {}

  @registerUtterance: (location, utterance, intentName) ->
    # Check if this utterance is already being handled by a different intent.
    if Intent.allUtterances[utterance]?
      prevIntentName = Intent.allUtterances[utterance].intentName
      prevIntentLocation = Intent.allUtterances[utterance].location
      if prevIntentName != intentName
        throw new ParserError location, "The utterance '#{utterance}' in the intent handler for
          '#{intentName}' was already handled by the intent '#{prevIntentName}' at
          #{formatLocationStart(prevIntentLocation)} -> utterances should be uniquely handled
          by a single intent: Alexa tries to map a user utterance to an intent, so one utterance
          being associated with multiple intents causes ambiguity (which intent was intended?)"
      # else, the utterance was already registered for this intent - nothing to do
    else
      # Otherwise, add the utterance to our tracking index.
      Intent.allUtterances[utterance] = { intentName: intentName, location: location }

  @unregisterUtterances: () ->
    Intent.allUtterances = {}

  @utteranceToName: (location, utterance) ->
    if utterance.isUtterance
      identifierFromString(location, utterance.toString())
    else
      utterance

  constructor: (args) ->
    @location = args.location
    utterance = args.utterance

    @utterances = []
    @allLocations = [@location]
    @slots = {}

    if utterance.isUtterance
      try
        @name = identifierFromString(@location, utterance.toString())
      catch err
        throw new ParserError @location, "cannot use the utterance `#{utterance}` as an intent name:
          #{err}"
      @pushUtterance utterance
    else
      @name = utterance
      @hasUtterances = false
      @validateBuiltIn()

    # Well no, actually. Events like Connection.Response and GameEngine.InputHandlerEvent
    # are kosher too. Work out how to pipe visibility of those down here later
    if false
      if @name.indexOf('.') >= 0
        unless @name.match /AMAZON\.[A-Za-z_]/
          throw new ParserError @location, "Intent names cannot contain a period unless they
            refer to a built in intent beginning with `AMAZON.`"
    @builtin = @name in builtInIntents
    @hasContent = false
    @childIntents = []

  report: ->
    "#{@name} {#{k for k of @slots}}"

  validateStateTransitions: (allStateNames, language) ->
    @startFunction?.validateStateTransitions(allStateNames, language)

  validateBuiltIn: ->
    parts = @name.split('.')
    key = parts.shift()
    if key of builtInReference
      intents = builtInReference[key]
      unless parts of intents
        throw new ParserError @location, "Unrecognized built in intent `#{@name}`"
      @hasUtterances = true # implied ones, even before extension ones
    # @TODO: plugin types?

  collectDefinedSlotTypes: (context, customSlotTypes) ->
    return if @referenceIntent?
    try
      for name, slot of @slots
        slot.collectDefinedSlotTypes context, customSlotTypes
    catch err
      throw err if err.isParserError
      throw new ParserError @location, err

  validateSlotTypes: (customSlotTypes) ->
    return if @referenceIntent?
    for name, slot of @slots
      slot.validateSlotTypes customSlotTypes

  supportsLanguage: (language) ->
    unless @startFunction?
      return true
    return language of @startFunction.languages

  resetCode: ->
    @hasContent = false
    @startFunction = null

  pushCode: (line) ->
    @startFunction = @startFunction ? new Function
    @startFunction.pushLine(line)
    @hasContent = true

  pushUtterance: (utterance) ->
    if @referenceIntent?
      return @referenceIntent.pushUtterance utterance

    # normalize the utterance text to lower case: capitalization is irrelevant
    utterance.visit 0, (depth, part) ->
      if part.isStringPart
        part.text = part.text.toLowerCase()

    for u in @utterances
      return if u.isEquivalentTo utterance

    @utterances.push utterance
    @hasUtterances = true
    utterance.visit 0, (depth, part) =>
      return unless part.isSlot
      unless @slots[part.name]
        @slots[part.name] = new Slot(part.name)

    Intent.registerUtterance(@location, utterance, @name)

  pushAlternate: (location, utterance, skill) ->
    if @hasChildIntents()
      throw new ParserError location, "Can't add this utterance as an 'or' alternative
        here because this handler already specifies multiple intents. Add the alternative
        to one of the original intent declarations instead."
    @hasAlternateUtterance = true
    @pushUtterance utterance

  pushChildIntent: (intent) ->
    @childIntents.push(intent.name)

  hasChildIntents: ->
    return @childIntents.length > 0

  pushSlotType: (location, name, type) ->
    if @referenceIntent?
      return @referenceIntent.pushSlotType location, name, type

    unless name of @slots
      throw new ParserError location, "There is no slot named #{name} here"

    @slots[name].setType location, type

  toLambda: (output, options) ->
    indent = "    "
    @startFunction?.toLambda(output, indent, options)

  hasStatementsOfType: (types) ->
    if @startFunction?
      return true if @startFunction.hasStatementsOfType(types)
    return false

  collectRequiredAPIs: (apis) ->
    @startFunction?.collectRequiredAPIs(apis)

  toUtterances: (output) ->
    return if @referenceIntent?
    return unless @hasUtterances

    for u in @utterances
      output.push "#{@name} #{u.toUtterance()}"

  toModelV2: (context) ->
    return if @referenceIntent?

    if @qualifier?
      if @qualifier.isStatic()
        condition = @qualifier.evaluateStatic context
        if @qualifierIsInverted
          condition = not condition
        return null unless condition
      else
        throw new ParserError @qualifier.location, "intent conditionals must be static expressions"

    result =
      name: @name

    # Check if we have a localization map, and if so whether we have translated utterances.
    localizedIntent = context.skill?.projectInfo?.localization?.intents?[@name]
    if context.language != 'default' && (localizedIntent?[context.language])
      result.samples = localizedIntent[context.language]
    else
      result.samples = ( u.toModelV2(context) for u in @utterances )

    if @slots
      slots = []
      for name, slot of @slots
        try
          slot.toModelV2 context, slots
        catch err
          throw new ParserError @location, "error writing intent `#{@name}`: #{err}"
      if slots.length > 0
        result.slots = slots

    return result

  toLocalization: (localization) ->
    @startFunction?.toLocalization(localization)

    for utterance in @utterances
      finalUtterance = utterance.toModelV2() # replace any $slot with {slot}
      unless localization.intents[@name].default.includes(finalUtterance)
        # if this is a newly added utterance, add it to the localization map
        localization.intents[@name].default.push(finalUtterance)



# Class that supports intent filtering.
class lib.FilteredIntent extends lib.Intent
  constructor: (args) ->
    super args
    @startFunction = new FunctionMap
    @intentFilters = {}

  # Method to filter intents via a passed filter function; can trigger optional callbacks.
  # @param name ... name used for scoping
  # @param data ... this is filter data that can be used to persist pegjs pattern data
  # @param filter ... function(request, data) that returns true/false for the incoming request
  # @param callback ... lambda code that can be run if a filtered intent is found
  setCurrentIntentFilter: ({ name, data, filter, callback }) ->
    @startFunction.setCurrentName name

    @intentFilters[name] = {
      data
      filter
      callback
    }

  toLambda: (output, options) ->
    indent = '    '

    # '__' is our catch-all default -> do not apply any filter
    if @intentFilters['__']
      options.scopeManager.pushScope @location, @name
      output.push "#{indent}// Unfiltered intent handling logic."
      @startFunction.toLambda(output, indent, options, '__')
      options.scopeManager.popScope @location
      delete @intentFilters['__'] # remove default, so we can easily check if any filters remain

    if Object.keys(@intentFilters).length > 0
      output.push "#{indent}// Filtered intent handling logic."
      output.push "#{indent}let __intentFilter;"

      for intentFilterName, intentFilter of @intentFilters
        continue unless intentFilter
        options.scopeManager.pushScope @location, "#{@name}:#{intentFilterName}"
        filterFuncString = Utils.stringifyFunction(intentFilter.filter, "#{indent}  ")
        output.push "#{indent}__intentFilter = #{filterFuncString}"
        output.push "#{indent}if (__intentFilter(context.event.request, #{JSON.stringify(intentFilter.data)})) {"

        # If the filter specified a callback, run it before proceeding to the intent handler.
        if intentFilter.callback?
          callbackString = Utils.stringifyFunction(intentFilter.callback, "#{indent}    ")
          output.push "#{indent}  await (#{callbackString})();"

        # Inject the filtered intent handler.
        @startFunction.toLambda(output, "#{indent}  ", options, intentFilterName)
        output.push "#{indent}}"
        options.scopeManager.popScope @location
