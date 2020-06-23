###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

lib = module.exports.lib = {}
{ ParserError, formatLocationStart } = require("./errors.coffee").lib


compileSlot = (context, type) ->
  code = context.skill.getFileContents type.filename, context.language

  code = code.js ? code
  unless code
    throw new ParserError null, "Couldn't find contents of file #{type.filename} to build slot type"

  exports = {}
  try
    eval code
  catch err
    throw new ParserError null, "While compiling #{type.filename}: #{err}"

  unless (k for k of exports).length > 0
    throw new ParserError null, "Slot type builder file #{type.filename} does not appear to export
      any slot building functions"
  unless type.functionName of exports
    throw new ParserError null, "Slot type builder #{type.functionName} not found in
      #{type.filename}, saw these functions in there [#{(k for k of exports).join(',')}]"

  try
    data = exports[type.functionName](context.skill, context.language)
  catch err
    throw new ParserError null, "While building #{type.functionName} from #{type.filename}: #{err}"

  unless typeof(data) == 'object'
    throw new ParserError null, "Slot builder #{type.functionName} returned #{JSON.stringify data},
      expected an object in the form { name:"", values:[] }"

  for key in ['name', 'values']
    unless key of data
      throw new ParserError null, "Missing key `#{key}` in result of slot builder
        #{type.functionName}: #{JSON.stringify data}"

  for value, index in data.values
    if typeof(value) == 'string'
      data.values[index] =
        id: undefined
        name: {
          value: value
          synonyms: []
        }

  if data.name of context.types
    throw new ParserError null, "Duplicate slot type definition found for name `#{data.name}`.
      Please remove one."

  context.types[data.name] = data
  return data.name


createSlotFromArray = (context, slotName, values) ->
  typeName = "#{slotName}Type"

  if typeName of context.types
    throw new ParserError null, "Duplicate slot type definition found for name `#{typeName}` while
      creating implicit type for slot `#{slotName}`. Please remove conflicting definitions."

  type =
    name: typeName
    values: []

  for v in values
    type.values.push
      id: undefined
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
      if @type.filename? and @type.functionName?
        throw new ParserError location, "The slot named `#{@name}` already has a defined type from
          the slot builder: `#{@type.filename}:#{@type.functionName}`"
      else
        throw new ParserError location, "The slot named `#{@name}` already has a defined type:
          `#{@type}`"

    @type = type
    @typeLocation = location
    if typeof(@type) == 'string'
      @builtinType = @type.indexOf('AMAZON.') == 0

  collectDefinedSlotTypes: (context, customSlotTypes) ->
    unless @type?
      throw new ParserError null, "the slot named `#{@name}` doesn't have a 'with' statement
        defining its type"

    if Array.isArray @type
      typeName = createSlotFromArray(context, @name.toString(), @type)
      customSlotTypes.push typeName
    else if @type.isFileFunctionReference
      typeName = compileSlot(context, @type)
      customSlotTypes.push typeName

  validateSlotTypes: (customSlotTypes) ->
    # @TODO: Validate built in types? Maybe just a warning?
    if typeof(@type) == 'string' and not @builtinType
      unless @type in customSlotTypes
        throw new ParserError @typeLocation, "the slot type named `#{@type}` is not defined
          anywhere"

  toModelV2: (context, slots) ->
    unless @type?
      throw new ParserError null, "missing type for slot `#{@name}`"

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






class lib.Utterance
  constructor: (@location, @root) ->
    unless @root?
      throw new ParserError @location, "Utterance constructed with no part (this shouldn't happen, contact a member of the litexa dev team!)"

  isUtterance: true

  visit: (depth, fn) ->
    @root.visit (depth+1), fn

  toString: ->
    return @root.toString()

  toUtterance: ->
    # we can trim excess white space from the full utterances since
    # it doesn't actually count for anything in the model, and this way
    # you can use as much or as little white space as makes for the best
    # legibility in the expression
    utterances = @root.toUtterance()
    utterances = for u in utterances
      u.trim().replace( /\s+/g, ' ' )
    return utterances

  toModelV2: ->
    return @toUtterance()

  parse: (line) ->
    unless @regex?
      @testScore = @root.toTestScore?() ? 0
      regexText = @root.toRegex?() ? "ROOT_UNSUPPORTED"
      regexText = "^#{regexText}$"
      @regex = new RegExp(regexText, 'i')

    match = @regex.exec(line)
    return [null, null] unless match?

    # this is a map of slot name -> slot value
    slots = {}
    if match.groups?
      # note, this relies on named captures, which means we're at minimum v10 of node now
      slots[k] = v for k, v of match.groups


    return [@testScore, slots]

  isEquivalentTo: (otherUtterance) ->
    return JSON.stringify(otherUtterance.toUtterance()) == JSON.stringify(@toUtterance())

  isUtterance: true