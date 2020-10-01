{ ParserError } = require('./errors.coffee').lib

lib = {}
module.exports = lib

class lib.DatabaseReferencePart
  constructor: (@ref) ->
  isDB: true
  needsEscaping: true
  toString: -> return "@#{@ref.toString()}"
  toUtterance: ->
    throw new ParserError null, "you cannot use a database reference in an utterance"
  toLambda: (options) ->
    return "context.db.read('#{@ref.base}')#{@ref.toLambdaTail()}"
  express: (context) ->
    return "STUB" if context.noDatabase
    return "" + @ref.readFrom(context.db)
  toRegex: ->
    return "([\\S\u00A0]+)"
  toTestRegex: -> @toRegex()
  toLocalization: (localization) ->
    return @toString()



class lib.StaticVariableReferencePart
  constructor: (@ref) ->
  needsEscaping: true
  isStatic: -> true
  toString: -> return "DEPLOY.#{@ref.toString()}"
  toUtterance: ->
    throw new ParserError null, "you cannot use a static reference in an utterance"
  toLambda: (options) ->
    return "litexa.DEPLOY.#{@ref.toLambda()}"
  express: (context) ->
    return eval "context.lambda.litexa.DEPLOY.#{@ref.toLambda()}"
  evaluateStatic: (context) ->
    return eval "context.skill.projectInfo.DEPLOY.#{@ref.toLambda()}"
  toRegex: ->
    throw "missing toRegex function for StaticVariableReferencePart"
  toTestRegex: -> @toRegex()
  toLocalization: (localization) ->
    return @toString()


class lib.DatabaseReferenceCallPart
  constructor: (@ref, @args) ->
  isDB: true
  needsEscaping: true
  toString: ->
    args = (a.toString() for a in @args).join ', '
    return "@#{@ref.toString()}(#{args})"
  toUtterance: ->
    throw new ParserError null, "you cannot use a database reference in an utterance"
  toLambda: (options) ->
    args = (a.toLambda(options) for a in @args).join ', '
    return "(await context.db.read('#{@ref.base}')#{@ref.toLambdaTail()}(#{args}))"
  express: (context) ->
    return "STUB" if context.noDatabase
    return "" + @ref.readFrom(context.db)
  toRegex: ->
    return "([\\S\u00A0]+)"
  toTestRegex: -> @toRegex()
  toLocalization: (localization) ->
    return @toString()


class lib.SlotReferencePart
  constructor: (@name) ->
  isSlot: true
  needsEscaping: true
  visit: (depth, fn) -> fn(depth, @)
  toString: -> return "$#{@name}"
  toUtterance: -> [ "{#{@name}}" ]
  toLambda: (options) -> return "context.slots.#{@name.toLambda(options)}"
  express: (context) ->
    if @fixedValue
      return "$#{@name}"
    return "" + context.slots[@name]
  toRegex: ->
    cleanName = @name.toString().replace(/\./g, '_')
    return "(?<#{cleanName}>[\\$\\S\u00A0]+)"
  toTestRegex: -> @toRegex()
  toTestScore: -> return 1
  toLocalization: (localization) ->
    return @toString()