
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


lib = module.exports.lib = {}

Function = require("./function.coffee").lib.Function
{ ParserError } = require("./errors.coffee").lib
{ LocalizationContext } = require('./localization.coffee')


builtInIntents = [
  "AMAZON.NoIntent"
  "AMAZON.YesIntent"
  "AMAZON.CancelIntent"
  "AMAZON.StopIntent"
  "AMAZON.HelpIntent"
  "AMAZON.StartOverIntent"
  "AMAZON.RepeatIntent"
  "AMAZON.PauseIntent"
  "AMAZON.PreviousIntent"
  "AMAZON.NextIntent"
  "AMAZON.ScrollUpIntent"
  "AMAZON.ScrollLeftIntent"
  "AMAZON.ScrollDownIntent"
  "AMAZON.ScrollRightIntent"
  "AMAZON.PageUpIntent"
  "AMAZON.PageDownIntent"
  "AMAZON.MoreIntent"
  "AMAZON.NavigateHomeIntent"
  "AMAZON.NavigateSettingsIntent"
  "AMAZON.FallbackIntent"
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


identifierFromString = (str) ->
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
    throw "utterance reduces to unsuitable intent name `#{str}`.
      You may need to use an explicit intent name instead?"
  # must start with a letter
  unless str[0].match /[A-Za-z]/
    str = 'i' + str
  str


class lib.Utterance
  constructor: (@parts) ->


  toString: ->
    return ( p.toString() for p in @parts ).join('')

  toUtterance: ->
    return ( p.toUtterance() for p in @parts ).join('')

  toModelV2: ->
    return @toUtterance()

  parse: (line) ->
    unless @regex?
      @testScore = 0
      @testScore += p.toTestScore() for p in @parts
      regexText = ( p.toRegex() for p in @parts ).join('')
      regexText = "^#{regexText}$"
      @regex = new RegExp(regexText, 'i')

    match = @regex.exec(line)
    return [null, null] unless match?

    result = {}
    for read, idx in match[1..]
      part = @parts[idx]
      if part?.isSlot
        result[part.name] = read
    return [@testScore, result]

  isEquivalentTo: (otherUtterance) ->
    return otherUtterance.toUtterance() == @toUtterance()

  isUtterance: true


compileSlot = (context, type) ->
  code = context.skill.getFileContents type.filename, context.language

  code = code.js ? code
  unless code
    throw "Couldn't find contents of file #{type.filename} to build slot type"

  exports = {}
  try
    eval code
  catch err
    throw "While compiling #{type.filename}: #{err}"

  unless (k for k of exports).length > 0
    throw "Slot type builder file #{type.filename} does not appear to export any slot building functions"
  unless type.functionName of exports
    throw "Slot type builder #{type.functionName} not found in #{type.filename}, saw these functions in there [#{(k for k of exports).join(',')}]"

  try
    data = exports[type.functionName](context.skill, context.language)
  catch err
    throw "While building #{type.functionName} from #{type.filename}: #{err}"

  unless typeof(data) == 'object'
    throw "Slot builder #{type.functionName} returned #{JSON.stringify data}, expected an object in the form { name:"", values:[] }"

  for key in ['name', 'values']
    unless key of data
      throw "Missing key #{key} in result of slot builder #{type.functionName}: #{JSON.stringify data}"

  for value, index in data.values
    if typeof(value) == 'string'
      data.values[index] =
        id: null
        name: {
          value: value
          synonyms: []
        }

  if data.name of context.types
    throw "Duplicate slot type definition found for name `#{data.name}`. Please remove one."

  context.types[data.name] = data
  return data.name


createSlotFromArray = (context, slotName, values) ->
  typeName = "#{slotName}Type"

  if typeName of context.types
    throw "Duplicate slot type definition found for name `#{typeName}` while creating implicit type for slot `#{slotName}`. Please remove conflicting definitions."

  type =
    name: typeName
    values: []

  for v in values
    type.values.push
      id: null
      name: {
        value: JSON.parse v
        synonyms: []
      }

  if context?
    context.types[typeName] = type

  return typeName


class lib.Slot
  constructor: (@name) ->

  setType: (location, type) ->
    if @type?
      throw new ParserError location, "The slot named `#{@name}` already has a defined type: `#{@type}`"

    @type = type
    @typeLocation = location
    if typeof(@type) == 'string'
      @builtinType = @type.indexOf('AMAZON.') == 0

  collectDefinedSlotTypes: (context, customSlotTypes) ->
    unless @type?
      throw "the slot named `#{@name}` doesn't have a when statement defining its type"

    if Array.isArray @type
      typeName = createSlotFromArray(context, @name.toString(), @type)
      customSlotTypes.push typeName
    else if @type.isFileFunctionReference
      typeName = compileSlot(context, @type)
      customSlotTypes.push typeName


  validateSlotTypes: (customSlotTypes) ->
    # todo: validate built in types? Maybe just a warning?

    if typeof(@type) == 'string' and not @builtinType
      unless @type in customSlotTypes
        throw new ParserError @typeLocation, "the slot type named `#{@type}` is not defined anywhere"


  toModelV2: (context, slots) ->
    unless @type?
      throw "missing type for slot `#{@name}`"

    if Array.isArray @type
      slots.push {
        name: @name.toString()
        type: createSlotFromArray(context, @name.toString(), @type)
      }
    else if @type.isFileFunctionReference
      slots.push {
        name: @name.toString()
        type: compileSlot(context, @type)
      }
    else
      slots.push {
        name: @name.toString()
        type: @type
      }


class lib.Intent
  @utteranceToName: (utterance) ->
    if utterance.isUtterance
      identifierFromString(utterance.toString())
    else
      utterance

  constructor: (@location, utterance) ->
    @utterances = []
    @allLocations = [@location]
    @slots = {}
    if utterance.isUtterance
      @pushUtterance utterance
      try
        @name = identifierFromString(utterance.toString())
      catch err
        throw new ParserError @location, "cannot use the utterance
        `#{utterance}` as an intent name: #{err}"
      @hasUtterances = true
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
    # todo, plugin types?


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

    for u in @utterances
      return if u.isEquivalentTo utterance

    @utterances.push utterance
    @hasUtterances = true
    for part in utterance.parts when part.isSlot
      unless @slots[part.name]
        @slots[part.name] = new lib.Slot(part.name)

  pushAlternate: (parts) ->
    @pushUtterance new lib.Utterance parts

  pushSlotType: (location, name, type) ->
    if @referenceIntent?
      return @referenceIntent.pushSlotType location, name, type

    unless name of @slots
      throw new ParserError location, "There is no slot named #{name} here"

    @slots[name].setType location, type


  toLambda: (output, options) ->
    indent = "    "
    if @startFunction?
      @startFunction.toLambda(output, indent, options)

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

    result =
      name: @name

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

  toLocalization: (result, context) ->
    if @startFunction?
      @startFunction.toLocalization(result, context)
