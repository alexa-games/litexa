###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

lib = module.exports.lib = {}

{ ParserError } = require('./errors.coffee').lib
{ AssetName } = require('./assets.coffee').lib
{ replaceNewlineCharacters, isEmptyContentString, isFirstOrLastItemOfArray, dedupeNonNewlineConsecutiveWhitespaces,
cleanTrailingSpaces, cleanLeadingSpaces } = require('./utils.coffee').lib

class lib.StringPart
  constructor: (text) ->
    # Whitespace and line break rules:
    #   line breaks are converted to whitespaces
    #   empty (or whitespace-only) lines are considered a line break
    #   consecutive whitespaces are condensed to a single whitespace
    splitLines = text.split('\n')
    lines = splitLines.map((str, idx) ->
      return '\n' if isEmptyContentString(str) and !isFirstOrLastItemOfArray(idx, splitLines)
      return str.trim() unless isFirstOrLastItemOfArray(idx, splitLines)
      return dedupeNonNewlineConsecutiveWhitespaces(str)
    )

    @tagClosePos = null
    if lines.length > 1
      @tagClosePos = lines[0].length + 1
      if lines[0] == '\n'
        @tagClosePos += 1
    @text = lines.join(' ')
    transformations = [
      cleanTrailingSpaces,
      cleanLeadingSpaces,
      dedupeNonNewlineConsecutiveWhitespaces
    ]
    transformations.forEach((transformation) =>
      @text = transformation(@text)
    )

  toString: -> return @text
  toUtterance: -> return @text
  toLambda: (options) ->
    # escape quotes
    str = @text.replace(/"/g, '\"')
    # escape line breaks
    str = replaceNewlineCharacters(str, '\\n')
    return '"' + str + '"'
  express: (context) ->
    return @text
  toRegex: ->
    str = @text
    # escape regex control characters
    str = str.replace( /\?/g, '\\?' )
    str = str.replace( /\./g, '\\.' )
    # mirror the line break handling for the lambda
    str = replaceNewlineCharacters(str, '\\n')
    "(#{str})"
  toTestRegex: -> @toRegex()
  toTestScore: -> return 10
  toLocalization: -> @toString()


class lib.TagPart
  constructor: (skill, @location, @code, @content, @variable) ->
    validFontSizes = [2, 3, 5, 7]
    @attributes = {}
    @open = false

    openUnlessContent = =>
      @open = true
      if @content?.trim().length > 0
        @open = false

    switch @code
      when "!"
        @tag = 'say-as'
        @attributes =
          'interpret-as': 'interjection'
      when "..."
        @tag = 'break'
        @attributes =
          time: @variable
      when "sfx"
        @tag = null
        @proxy = @content
        @content = null
      when "fontsize"
        unless parseInt(@variable) in validFontSizes
          throw new ParserError @location, "invalid font size #{@variable}, expecting one of #{JSON.stringify validFontSizes}"
        @tag = 'font'
        @attributes =
          size: @variable
        openUnlessContent()
      when "center"
        @tag = 'div'
        @attributes =
          align: 'center'
        openUnlessContent()
      when "i", "b", "u"
        @tag = @code
        openUnlessContent()
      else
        # look at extensions that might handle this
        extensions = skill.getExtensions()
        info = null
        if extensions?
          for name, ext of extensions
            info = ext?.language?.sayTags?[@code]
            break if info?
        unless info?
          throw new ParserError @location, "unknown tag <#{@code}>"
        info.process?(@)


  toString: -> return "<#{@code} #{@text}>"
  toUtterance: ->
    throw new ParserError null, "you cannot use a tag part in an utterance"
  toSSML: (language) ->
    unless language
      language = "default"
    if @tag?
      attributes = ( "#{k}='#{v}'" for k, v of @attributes )
      if @codeAttributes?
        for k, v of @codeAttributes
          attributes.push """#{k}='" + #{v} + "'"""
      attributes = attributes.join ' '
      if attributes.length > 0
        attributes = ' ' + attributes
      if @open
          "<#{@tag}#{attributes}>"
      else
        if @content
          "<#{@tag}#{attributes}>#{@content}</#{@tag}>"
        else
          "<#{@tag}#{attributes}/>"
    else if @proxy?
      @proxy.toSSML language
    else if @verbatim
      @verbatim
    else
      ""

  toLambda: (options) ->
    if @proxy?
      return @proxy.toSSMLFunction options.language
    '"' + @toSSML(options.language) + '"'

  express: (context) -> @toSSML(context.language)
  toRegex: ->
    str = @toSSML()
    # escape regex control characters
    str = str.replace( /\?/g, '\\?' )
    str = str.replace( /\./g, '\\.' )
    str = str.replace( /\//g, '\\/' )
    "(#{str})"
  toTestRegex: ->
    switch @code
      when "!"
        "(#{@toRegex()}|(<!#{@content}>))"
      when "..."
        "(#{@toRegex()}|(<...#{@attributes.time}>))"
      when "sfx"
        testSFXMatch = "#{if (@proxy?.name && @proxy?.type) then "|(<#{@proxy.name}.#{@proxy.type}>)|(<#{@proxy.name}>)" else ''}"
        "(#{@toRegex()}#{testSFXMatch})"
      else
        @toRegex()

  toTestScore: -> return 9
  toLocalization: -> @toString()


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
  toLocalization: (context) ->
    reference = context.registerVariable @toString()
    "{#{reference}}"



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
  toLocalization: (context) ->
    throw "missing toLocalization function for StaticVariableReferencePart"



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
  toLocalization: (context) ->
    reference = context.registerVariable @toString()
    "{#{reference}}"


class lib.SlotReferencePart
  constructor: (@name) ->
  isSlot: true
  needsEscaping: true
  toString: -> return "$#{@name}"
  toUtterance: -> "{#{@name}}"
  toLambda: (options) -> return "context.slots.#{@name.toLambda(options)}"
  express: (context) ->
    if @fixedValue
      return "$#{@name}"
    return "" + context.slots[@name]
  toRegex: ->
    return "([\\$\\S\u00A0]+)"
  toTestRegex: -> @toRegex()
  toTestScore: -> return 1
  toLocalization: (context) ->
    reference = context.registerVariable @toString()
    "{#{reference}}"


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
  toLocalization: (context) ->
    reference = context.registerVariable "" + @expression
    "{#{reference}}"


class lib.JavaScriptFragmentPart
  constructor: (@func) ->
  toString: -> return "{ #{@func}}"
  toUtterance: -> throw new ParserError null, "you cannot use a JavaScript reference in an utterance"
  toLambda: (options) -> return "#{@func}"
  express: (context) -> return @func
  toRegex: -> throw new Error "JavaScriptFragmentPart can't be matched in a regex"
  toTestRegex: -> @toRegex()


class lib.AssetNamePart
  constructor: (@assetName) ->
  isAssetNamePart: true
  toString: -> return "<#{@assetName}>"
  toUtterance: -> throw new ParserError @assetName.location, "can't use an asset name part in an utterance"
  toLambda: (options) -> return @assetName.toSSML(options.language)
  express: (context) -> return @toString()
  toRegex: ->
    return "(#{@toSSML()})"
  toTestRegex: -> @toRegex()
  toTestScore: -> return 10


class lib.SayEchoPart
  constructor: (@assetName) ->
  isSayEcho: true
  toString: -> return "<as say>"
  toUtterance: -> throw new ParserError @assetName.location, "can't use an Echo part in an utterance"
  toLambda: (options) -> return ""
  express: -> ""
  toRegex: -> return ""
  toTestRegex: -> @toRegex()
  toTestScore: -> return 0


partsToExpression = (parts, options) ->
  unless parts?.length > 0
    return "''"

  result = []
  tagContext = []
  closeTags = ->
    if tagContext.length == 0
      return ''
    closed = []
    for tag in tagContext by -1
      closed.push "</#{tag}>"
    tagContext = []
    '"' + closed.join('') + '"'

  result = for p in parts
    if p.open
      tagContext.push p.tag

    code = p.toLambda options

    if p.tagClosePos?
      closed = closeTags()
      if closed
        before = code[0...p.tagClosePos] + '"'
        after = '"' + code[p.tagClosePos..]
        #console.log [before, after]
        code =  [before, closed, after].join '+'

    if p.needsEscaping
      "escapeSpeech( #{code} )"
    else
      code

  closed = closeTags()
  if closed
    result.push closed
  result.join(' + ')


class lib.Say
  constructor: (parts) ->
    @alternates = [ parts ]

  isSay: true

  pushAlternate: (parts) ->
    @alternates.push parts

  toString: ->
    if @alternates.length == 0
      return ""
    (p.toString() for p in @alternates[0]).join('')

  toExpression: (options) ->
    partsToExpression @alternates[0], options

  toLambda: (output, indent, options) ->
    targetFunction = "say"
    if @reprompt
      targetFunction = "reprompt"

    writeLine = (indent, parts) ->
      if parts[0]?.isSayEcho
        output.push "#{indent}context.repromptTheSay = true;"
      else
        line = partsToExpression(parts, options)
        if line and line != '""'
          output.push "#{indent}context.#{targetFunction}.push( #{line} );"

    if @alternates.length > 1
      sayKey = require('./sayCounter').get()
      output.push "#{indent}switch(pickSayString(context, #{sayKey}, #{@alternates.length})) {"
      for alt, idx in @alternates
        if idx == @alternates.length - 1
          output.push "#{indent}  default:"
        else
          output.push "#{indent}  case #{idx}:"
        writeLine indent + "    ", alt
        output.push "#{indent}    break;"
      output.push "#{indent}}"
    else
      writeLine indent, @alternates[0]

  toLocalization: (result, context) ->
    collectParts = (parts) ->
      locParts = []
      for p in parts when p.toLocalization?
        fragment = p.toLocalization(context)
        locParts.push fragment if fragment?
      locParts.join ''

    switch @alternates.length
      when 0 then return
      when 1
        context.pushDialog collectParts(@alternates[0])
      else
        context.pushDialog ( collectParts(a) for a in @alternates )


  express: (context) ->
    # given the info in the context, fully resolve the parts
    (p.express(context) for p in @alternates[0]).join("")

  matchFragment: (language, line, testLine) ->
    for parts in @alternates
      unless parts.regex?
        regexText = ( p.toTestRegex() for p in parts ).join('')
        # prefixed with any number of spaces to eat formatting
        # adjustments with fragments are combined in the skill
        parts.regex = new RegExp("\\s*" + regexText, '')

      match = parts.regex.exec(line)
      continue unless match?
      continue unless match[0].length > 0

      result =
        offset: match.index
        reduced: line.replace parts.regex, ''
        part: @
        removed: match[0]
        slots: {}
        dbs: {}

      for read, idx in match[1..]
        part = parts[idx]
        if part?.isSlot
          result.slots[part.name] = read
        if part?.isDB
          result.dbs[part.name] = read
      return result

    return null
