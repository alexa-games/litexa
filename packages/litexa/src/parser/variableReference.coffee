lib = module.exports.lib = {}

class lib.VariableReference
  constructor: (@base, @tail) ->

  isVariableReference: true

  toString: ->
    @base + @tail.join('')

  toExpression: (options) ->
    @toLambda(options)

  toLambda: (options) ->
    @base + @toLambdaTail(options)

  toLambdaTail: (options) ->
    return "" if @tail.length == 0
    ( p.toLambdaTail(options) for p in @tail ).join('')

  readFrom: (obj) ->
    return null unless obj?
    ref = obj[@base]
    for p in @tail
      ref = p.readFrom(ref)
    return ref

  evalTo: (obj, value, options) ->
    tail = @toLambda(options)
    expr = "obj.#{tail} = #{value}"
    eval expr

class lib.VariableArrayAccess
  constructor: (@index) ->
    if typeof(@index) == "string"
      @index = "'#{@index}'"

  toString: -> "[#{@index}]"

  toLambdaTail: (options) -> "[#{@index}]"

  readFrom: (obj) ->
    return null unless obj?
    return obj[@index]

class lib.VariableMemberAccess
  constructor: (@name) ->

  toString: -> ".#{@name}"

  toLambdaTail: (options) -> ".#{@name}"

  readFrom: (obj) ->
    return null unless obj?
    obj[@name]
