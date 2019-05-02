module.exports.lib = lib = {}

class ValidationError
  constructor: (@parameter, @message, @value) ->

  toString: ->
    if @value?
      "#{@parameter}: #{@value}, #{@message}"
    else
      "#{@parameter}, #{@message}"


formatParameter = (p) ->
  if p == ''
    return ''
  if typeof(p) == 'number'
    return "[#{p}]"
  p = ''  + p
  if p.match /[\.\s]/g
    return "[\"#{p}\"]"
  return ".#{p}"


class lib.JSONValidator
  # This class is  designed to discover and record problems with a JSON object

  constructor: (@jsonObject) ->
    @prefix = ''
    @prefixStack = []
    @errors = []

  push: (prefix, subRoutine) ->
    @prefixStack.push prefix
    @prefix = ( formatParameter(p) for p in @prefixStack ).join ''
    newValue = @getValue('')[1]
    if newValue
      subRoutine()
    else
      @fail prefix, "missing required object"
    @prefixStack.pop()

  fail: (parameter, message) ->
    loc = "#{@prefix}#{formatParameter parameter}"
    try
      value = eval("this.jsonObject" + loc)
      if value?
        value = JSON.stringify( value )
      else
        value = "[undefined]"
    catch
      value = "[undefined]"
    @errors.push new ValidationError loc, message, value

  failNoValue: (parameter, message) ->
    loc = "#{@prefix}#{formatParameter parameter}"
    @errors.push new ValidationError loc, message, null

  badKey: (parameter, key, message) ->
    loc = "this.jsonObject#{@prefix}#{formatParameter parameter}]"
    @errors.push new ValidationError loc, message, '"' + key + '"'

  strictlyOnly: (parameters) ->
    @require parameters
    @whiteList parameters

  require: (parameters) ->
    [loc, value] = @getValue('')
    unless value
      @errors.push new ValidationError loc, "expected an object with parameters [#{parameters.join ', '}]"
      return
    if typeof(parameters) == 'string'
      unless parameters of value
        @fail parameters, "missing required parameter"
    else
      for p in parameters
        unless p of value
          @fail p, "missing required parameter"

  whiteList: (parameters) ->
    [loc, value] = @getValue('')
    for k, v of value
      unless k in parameters
        @errors.push new ValidationError "#{loc}.#{k}", "unsupported parameter"

  integerBounds: (parameter, min, max) ->
    [loc, value] = @getValue(parameter)
    unless value? and typeof(value) == 'number' and Math.floor(value) == value
      if value?
        value = JSON.stringify(value)
      else
        value = '[undefined]'
      @errors.push new ValidationError loc, "should be an integer between #{min} and #{max}, inclusive", value
      return
    unless min <= value <= max
      @errors.push new ValidationError loc, "should be between #{min} and #{max}, inclusive", value
      return

  oneOf: (parameter, choices) ->
    [loc, value] = @getValue(parameter)
    unless value?
      @errors.push new ValidationError loc, "missing parameter"
      return
    unless value in choices
      value = JSON.stringify(value)
      @errors.push new ValidationError loc, "should only be one of #{JSON.stringify(choices)}", value

  boolean: (parameter) ->
    [loc, value] = @getValue(parameter)
    unless typeof(value) == 'boolean'
      @errors.push new ValidationError loc, "should be true or false", value

  getValue: (parameter) ->
    loc = "#{@prefix}#{formatParameter parameter}"
    if loc == ''
      return ['', @jsonObject]
    try
      value = eval("this.jsonObject" + loc)
    catch
      value = undefined
    [loc, value]

  length: ->
    @errors.length

  toString: ->
    @errors.join '\n'
