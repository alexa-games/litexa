###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

lib = module.exports.lib = {}
{ LocalizationContext } = require('./localization.coffee')
{ ParserError } = require("./errors.coffee").lib


operatorMap =
  '+': '+'
  '-': '-'
  '*': '*'
  '/': '/'
  '==': '==='
  '===': '==='
  '!=': '!=='
  '!==': '!=='
  '<': '<'
  '<=': '<='
  '>': '>'
  '>=': '>='
  'else': 'else'
  'expr': 'expr'
  'regex': 'regex'
  'and': '&&'
  '&&': '&&'
  'or': '||'
  '||': '||'


isStaticValue = (v) ->
  switch typeof(v)
    when 'string' then return true
    when 'number' then return true 
    when 'boolean' then return true 
    when 'object' then return v.isStatic?()
  return false

evaluateStaticValue = (v, context, location) ->
  switch typeof(v)
    when 'string' 
      if v[0] == '"' and v[v.length-1] == '"'
        return v[1...v.length-1]
      else 
        return v
    when 'number' then return v 
    when 'boolean' then return v 
    when 'object' 
      unless v.evaluateStatic?
        throw new ParserError location, "missing evaluateStatic for #{JSON.stringify(v)}"
      try 
        return v.evaluateStatic(context)
      catch err
        throw new ParserError location, "Error in static evaluation: #{err}"
  throw "don't know how to static evaluate #{JSON.stringify(v)}"


class lib.EvaluateExpression
  constructor: (@expression) ->

  toLambda: (output, indent, options) ->
    output.push "#{indent}#{@expression.toLambda(options)}"


class lib.Expression
  constructor: (@location, @root) ->
    unless @root?
      throw new ParserError @location, "expression with no root?"

  isStatic: ->
    return isStaticValue(@root)

  evaluateStatic: (context) ->
    evaluateStaticValue @root, context, @location

  toString: ->
    @root.toString()

  toLambda: (options, keepRootParentheses) ->
    if @root.toLambda?
      @root.skipParentheses = not ( keepRootParentheses ? false )
      return @root.toLambda(options)
    return @root


class lib.BinaryExpression
  constructor: (@location, @left, @op, @right) ->
    unless @op of operatorMap
      throw new ParserError @location, "unrecognized operator #{@op}"

  isStatic: ->
    return isStaticValue(@left) and isStaticValue(@right)

  evaluateStatic: (context) ->
    left = evaluateStaticValue @left, context, @location
    right = evaluateStaticValue @right, context, @location
    op = operatorMap[@op]
    eval "#{JSON.stringify left} #{op} #{JSON.stringify right}"

  toLambda: (options) ->
    left = @left
    if @left.toLambda?
      left = @left.toLambda(options)
    right = @right
    if @right.toLambda?
      right = @right.toLambda(options)
    op = operatorMap[@op]
    if @skipParentheses
      "#{left} #{op} #{right}"
    else
      "(#{left} #{op} #{right})"

class lib.LocalExpressionCall
  constructor: (@location, @name, @arguments) ->

  toLambda: (options) ->
    args = []
    for a in @arguments
      if a.toLambda?
        args.push a.toLambda(options)
      else
        args.push a

    options.scopeManager.checkAccess @location, @name.base
    "await #{@name}(#{args.join(', ')})"


class lib.DBExpressionCall
  constructor: (@location, @name, @arguments) ->

  toLambda: (options) ->
    args = []
    for a in @arguments
      if a.toLambda?
        args.push a.toLambda(options)
      else
        args.push a

    "await context.db.read('#{@name.base}')#{@name.toLambdaTail(options)}(#{args.join(', ')})"


class lib.IfCondition
  constructor: (@expression, @negated) ->

  pushCode: (line) ->
    @startFunction = @startFunction ? new lib.Function
    @startFunction.pushLine(line)

  validateStateTransitions: (allStateNames, language) ->
    @startFunction?.validateStateTransitions?(allStateNames, language)

  toLambda: (output, indent, options) ->
    unless options.language
      throw "missing language in if"
    if @negated
      output.push "#{indent}if (!(#{@expression.toLambda(options)})) {"
    else
      output.push "#{indent}if (#{@expression.toLambda(options)}) {"
    @startFunction?.toLambda(output, indent + "  ", options)
    output.push "#{indent}}"

  hasStatementsOfType: (types) ->
    if @startFunction?
      return @startFunction.hasStatementsOfType(types)
    return false

  collectRequiredAPIs: (apis) ->
    @startFunction?.collectRequiredAPIs?(apis)

  toLocalization: (result, context) ->
    return unless @startFunction?
    subContext = new LocalizationContext
    @startFunction.toLocalization(result, subContext)
    if subContext.hasContent()
      context.pushOption @expression, subContext


class lib.ElseCondition
  constructor: (@expression) ->

  pushCode: (line) ->
    @startFunction = @startFunction ? new lib.Function
    @startFunction.pushLine(line)

  validateStateTransitions: (allStateNames, language) ->
    @startFunction?.validateStateTransitions?(allStateNames, language)

  toLambda: (output, indent, options) ->
    if @expression
      output.push "#{indent}else if (#{@expression.toLambda(options)}) {"
    else
      output.push "#{indent}else {"
    @startFunction?.toLambda(output, indent + "  ", options)
    output.push "#{indent}}"

  hasStatementsOfType: (types) ->
    if @startFunction?
      return @startFunction.hasStatementsOfType(types)
    return false

  collectRequiredAPIs: (apis) ->
    @startFunction?.collectRequiredAPIs?(apis)

  toLocalization: (result, context) ->
    return unless @startFunction?
    subContext = new LocalizationContext
    @startFunction.toLocalization(result, subContext)
    if subContext.hasContent()
      context.pushOption (@expression ? "else"), subContext


class lib.ForStatement
  constructor: (@keyName, @valueName, @sourceName) ->

  pushCode: (line) ->
    @startFunction = @startFunction ? new lib.Function
    @startFunction.pushLine(line)

  validateStateTransitions: (allStateNames, language) ->
    @startFunction?.validateStateTransitions?(allStateNames, language)

  toLambda: (output, indent, options) ->
    tempKey = options.scopeManager.newTemporary(@location)

    code = []
    sourceName = @sourceName.toLambda(options)

    # lexically scope the block
    options.scopeManager.pushScope @location, 'for'

    code.push "for (let #{tempKey} in #{sourceName}){"
    if @valueName?
      options.scopeManager.allocate @location, @valueName
      code.push "  let #{@valueName} = #{sourceName}[#{tempKey}];"
    if @keyName?
      options.scopeManager.allocate @location, @keyName
      code.push "  let #{@keyName} = #{tempKey};"

    @startFunction?.toLambda(code, "  ", options)
    code.push "}"

    options.scopeManager.popScope()

    for l in code
      output.push indent + l


  hasStatementsOfType: (types) ->
    if @startFunction?
      return @startFunction.hasStatementsOfType(types)
    return false

  collectRequiredAPIs: (apis) ->
    @startFunction?.collectRequiredAPIs?(apis)

  toLocalization: (result, context) ->
    return unless @startFunction?
    subContext = new LocalizationContext
    @startFunction.toLocalization(result, subContext)
    if subContext.hasContent()
      context.pushOption @expression, subContext


class lib.SwitchStatement
  constructor: (@assignments) ->
    @cases = []

  pushCase: (switchCase) ->
    @cases.push switchCase

  validateStateTransitions: (allStateNames, language) ->
    for c in @cases
      c.validateStateTransitions?(allStateNames, language)

  toLambda: (output, indent, options) ->
    # switch statements are turned into cascading if/else statements
    # as we allow a variety of switching scenarios, while JavaScript
    # only supports jumping on integers.

    # if we have local assignments, then our scoping promise is
    # they won't be visible after the switch statement, which
    # means we'll need an extra block scope to contain them.
    needWrap = @assignments[0]?.needsScope()

    # either way, switch blocks are lexical scopes to us
    options.scopeManager.pushScope @location, "switch"

    if needWrap
      output.push "#{indent}{"
      childIndent = indent + "  "
    else
      childIndent = indent

    # each assignment becomes a local variable
    for a in @assignments
      a.toLambda(output, childIndent, options)

    # if we have at least one assignment, then they
    # become the implicit variable in case comparisons.
    # if it's non trivial, then we cache it in a local variable
    implicit = @assignments[0]?.stringName

    # let each case generate their chunk
    for c, idx in @cases
      c.toLambda(output, childIndent, options, idx==0, implicit)

    if needWrap
      output.push "#{indent}}"

    options.scopeManager.popScope()


class lib.SwitchAssignment
  constructor: (@location, @name, @value) ->

  needsScope: ->
    @value? or @name?.toLambda?

  toLambda: (output, indent, options) ->
    @stringName = @name
    if @name?.toLambda?
      @stringName = @name.toLambda(options)

    if @stringName? and @value?
      # if we're assigning a value, this needs to be a new var
      options.scopeManager.allocate @location, @stringName

    unless @stringName
      # if no name, then it's the implicit, and we'll make this a temporary
      @stringName = options.scopeManager.newTemporary(@location)

    if @value?
      # if there isn't a value, then this is just importing the implicit
      output.push "#{indent}let #{@stringName} = #{@value.toLambda(options)};"


class lib.SwitchCase
  constructor: (@location, @operator, @value) ->
    unless @operator of operatorMap
      throw new ParserError @location, "Unrecognized operator #{@operator}"

  pushCode: (line) ->
    @startFunction = @startFunction ? new lib.Function
    @startFunction.pushLine(line)

  validateStateTransitions: (allStateNames, language) ->
    @startFunction?.validateStateTransitions?(allStateNames, language)

  toLambda: (output, indent, options, first, implicit) ->
    if @operator == 'else'
      output.push "#{indent}else {"
    else
      cmd = if first then 'if' else 'else if'
      if @operator == 'expr'
        val = @value?.toLambda?(options, false)
        output.push "#{indent}#{cmd} (#{val}) {"
      else if @operator == 'regex'
        output.push "#{indent}#{cmd} (/#{@value.expression}/#{@value.flags}.test(#{implicit})) {"
      else
        val = @value?.toLambda?(options, true)
        op = operatorMap[@operator]
        output.push "#{indent}#{cmd} (#{implicit} #{op} #{val}) {"
    @startFunction?.toLambda(output, indent + "  ", options)
    output.push "#{indent}}"


class lib.SetSetting
  constructor: (@variable, @value) ->

  toLambda: (output, indent, options) ->
    output.push "#{indent}context.settings['#{@variable}'] = #{@value};"


class lib.DBAssignment
  constructor: (@name, @expression) ->

  toLambda: (output, indent, options) ->
    tail = @name.toLambdaTail()
    if tail == ""
      output.push "#{indent}context.db.write('#{@name.base}', #{@expression.toLambda(options)});"
    else
      output.push "#{indent}context.db.read('#{@name.base}')#{tail} = #{@expression.toLambda(options)};"

class lib.WrapClass
  constructor: (@className, @variableName, @source) ->

  toLambda: (output, indent, options) ->
    options.scopeManager.allocate @location, @variableName
    output.push "#{indent}var #{@variableName} = new #{@className}(context.db.read('#{@source}', true), context);"

class lib.DBTypeDefinition
  constructor: (@location, @name, @type) ->


class lib.LocalDeclaration
  constructor: (@name, @expression) ->

  toLambda: (output, indent, options) ->
    options.scopeManager.allocate @location, @name
    output.push "#{indent}let #{@name} = #{@expression.toLambda(options)};"

class lib.LocalVariableAssignment
  constructor: (@name, @expression) ->

  toLambda: (output, indent, options) ->
    options.scopeManager.checkAccess @location, @name
    output.push "#{indent}#{@name} = #{@expression.toLambda(options)};"

class lib.LocalVariableReference
  constructor: (@location, @name) ->

  toLambda: (options) ->
    options.scopeManager.checkAccess @location, @name.base
    @name.toLambda(options)


class lib.SlotVariableAssignment
  constructor: (@location, @name, @expression) ->
    if @name.base in ['request', 'event']
      throw new ParserError @location, "cannot assign to the reserved variable name `$#{@name}`"

  toLambda: (output, indent, options) ->
    output.push "#{indent}context.slots.#{@name} = #{@expression.toLambda(options)};"


class lib.Directive
  constructor: (@expression) ->

  toLambda: (output, indent, options) ->
    expression = @expression.toLambda(options)
    code = """
    var __directives = #{expression};
    if (!__directives) { throw new Error('directive expression at line #{@location?.start?.line} did not return an array of directives'); }
    if (!Array.isArray(__directives)) {
      __directives = [__directives];
    }
    for(var i=0; i<__directives.length; ++i) {
      if (typeof(__directives[i]) == 'object') {
        context.directives.push(__directives[i]);
      } else {
        throw new Error('directive expression at line #{@location?.start?.line} produced item ' + i + ' that was not an object');
      }
    } """
    for line in code.split '\n'
      output.push indent + line

class lib.RecordMetric
  constructor: (@name) ->

  toLambda: (output, indent, options) ->
    output.push "#{indent}reportValueMetric('#{@name}', 1);"

class lib.SetResponseSpacing
  constructor: (@milliseconds) ->

  toLambda: (output, indent, options) ->
    output.push "#{indent}context.db.responseMinimumDelay = #{@milliseconds};"


class lib.Function
  constructor: ->
    @languages = {}

  pushLine: (line) ->
    unless line.location?.language
      throw "Missing language in line #{line.constructor?.name}"
    language = line.location.language
    unless language of @languages
      @languages[language] = []
    @languages[language].push line

  validateStateTransitions: (allStateNames, language) ->
    return unless @languages[language]?
    for line in @languages[language]
      line.validateStateTransitions?(allStateNames, language)

  toLambda: (output, indent, options) ->
    unless options.language
      console.error options
      throw "no language in toLambda"
    lines = @languages['default']
    if options.language of @languages
      lines = @languages[options.language]
    if lines?
      for line in lines
        unless line?.toLambda?
          console.error line
          throw "missing toLambda for #{line.constructor.name}"
        line.toLambda(output, indent, options)
    if @shouldEndSession
      output.push("context.shouldEndSession = true;")

  toLocalization: (result, context) ->
    return unless 'default' of @languages
    for line, idx in @languages.default
      if line.toLocalization?
        line.toLocalization(result, context)

  forEachPart: (language, cb) ->
    return unless @languages[language]
    for line in @languages[language]
      cb(line)

  hasStatementsOfType: (types) ->
    for lang, lines of @languages
      for line in lines
        if line.hasStatementsOfType
          return true if line.hasStatementsOfType(types)
    return false

  collectRequiredAPIs: (apis) ->
    for lang, lines of @languages
      for line in lines
        line.collectRequiredAPIs?(apis)


class lib.FunctionMap
  ###
    Interface compatible with Function, this is a
    convenience object for collecting named blocks of
    alternative functions.
  ###

  constructor: ->
    @currentName = '__'
    @functions = {}
    @functions[@currentName] = new lib.Function

  setCurrentName: (name) ->
    unless name of @functions
      @functions[name] = new lib.Function
    @currentName = name

  pushLine: (line) ->
    @functions[@currentName].pushLine line

  validateStateTransitions: (allStateNames, language) ->

  toLambda: (output, indent, options, name) ->
    return unless name?
    return unless name of @functions
    return @functions[name].toLambda output, indent, options

  toLocalization: (result, context) ->

  forEachPart: (language, cb) ->
    for n, f of @functions
      f.forEachPart language, cb

  hasStatementsOfType: (types) ->
    for n, f of @functions
      return true if f.hasStatementsOfType types
    return false

  collectRequiredAPIs: (apis) ->
    for n, f of @functions
      f.collectRequiredAPIs?(apis)
