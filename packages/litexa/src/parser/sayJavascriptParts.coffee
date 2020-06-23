{ ParserError } = require('./errors.coffee').lib

lib = {}
module.exports = lib

class lib.JavaScriptPart
  constructor: (@expression) ->
  isJavaScript: true
  needsEscaping: true
  toString: ->
    "{#{@expression.toString()}}"
  toUtterance: ->
    throw new ParserError null, "you cannot use a JavaScript reference in an utterance"
  toLambda: (options) ->
    "(#{@expression.toLambda(options)})"
  express: (context) ->
    @expression.toString()
    # func = (p.express(context) for p in @expression.parts).join(' ')
    try
      context.lambda.executeInContext(func)
    catch e
      #console.error "failed to execute `#{func}` in context: #{e}"
  toRegex: ->
    # assuming this can only match a single substitution
    return "([\\S\u00A0]+)"
  toTestRegex: -> @toRegex()
  toLocalization: (localization) ->
    return @toString()

