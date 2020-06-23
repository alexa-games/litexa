###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

lib = module.exports.lib = {}

lib[k] = v for k, v of require('./sayVariableParts.coffee')
lib[k] = v for k, v of require('./sayTagParts.coffee')
lib[k] = v for k, v of require('./sayJavascriptParts.coffee')
lib[k] = v for k, v of require('./sayFlowControlParts.coffee')

{ parseFragment } = require('./parser.coffee')
{ ParserError } = require('./errors.coffee').lib
{ AssetName } = require('./assets.coffee').lib
{
  replaceNewlineCharacters,
  isEmptyContentString,
  isFirstOrLastItemOfArray,
  dedupeNonNewlineConsecutiveWhitespaces,
  cleanTrailingSpaces,
  cleanLeadingSpaces
} = require('./utils.coffee').lib




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

  visit: (depth, fn) -> fn(depth, @)

  isStringPart: true
  toString: -> @text
  toUtterance: -> [ @text.toLowerCase() ]
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
  toLocalization: ->
    return @toString()


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
  constructor: (parts, skill) ->
    @alternates = {
      default: [ parts ]
    }
    @checkForTranslations(skill)

  isSay: true

  checkForTranslations: (skill) ->
    # Check if the localization map exists and has an entry for this string.
    localizationEntry = skill?.projectInfo?.localization?.speech?[@toString()]

    if localizationEntry?
      for language, translation of localizationEntry
        # ignore the translation if it's empty
        continue unless translation
        # ignore the translation if it isn't for one of the skill languages (could just be comments)
        continue unless Object.keys(skill.languages).includes(language)

        alternates = translation.split('|') # alternates delineation character is '|'

        for i in [0..alternates.length - 1]
          # parse the translation to identify the string parts
          fragment = """say "#{alternates[i]}" """

          parsedTranslation = null
          try
            parsedTranslation = parseFragment(fragment, language)
          catch err
            throw new Error("Failed to parse the following fragment translated for #{language}:\n#{fragment}\n#{err}")

          if i == 0
            # first (and potentially only) alternate
            @alternates[language] = parsedTranslation.alternates.default
          else
            # split by '|' returned more than one string -> this is an 'or' alternate
            @alternates[language].push(parsedTranslation.alternates.default[0])

  pushAlternate: (location, parts, skill, language = 'default') ->
    @alternates[language].push parts
    # re-check localization since alternates are combined into single key as follows:
    #   "speech|alternate one|alternate two"
    @checkForTranslations(skill)

  toString: (language = 'default') ->
    switch @alternates[language].length
      when 0 then return ''
      when 1
        return (p.toString() for p in @alternates[language][0]).join('')
      else
        return (a.join('').toString() for a in @alternates[language]).join('|')

  toExpression: (options, language = 'default') ->
    partsToExpression @alternates[language][0], options

  toLambda: (output, indent, options) ->
    speechTargets = ["say"]
    if @isReprompt
      speechTargets = [ "reprompt" ]
    else if @isAlsoReprompt
      speechTargets = speechTargets.concat "reprompt"

    writeAlternates = (indent, alternates) ->
      if alternates.length > 1
        sayKey = require('./sayCounter').get()
        output.push "#{indent}switch(pickSayString(context, #{sayKey}, #{alternates.length})) {"
        for alt, idx in alternates
          if idx == alternates.length - 1
            output.push "#{indent}  default:"
          else
            output.push "#{indent}  case #{idx}:"
          writeLine indent + "    ", alt
          output.push "#{indent}    break;"
        output.push "#{indent}}"
      else
        writeLine indent, alternates[0]

    writeLine = (indent, parts) ->
      line = partsToExpression(parts, options)
      for target in speechTargets
        if line and line != '""'
          output.push "#{indent}context.#{target}.push( (#{line}).trim().replace(/ +/g,' ') );"

    # Add language-specific output speech to the Lambda, if translations exist.
    alternates = @alternates[options.language] ? @alternates.default
    writeAlternates(indent, alternates)

  express: (context) ->
    # given the info in the context, fully resolve the parts
    if @alternates[context.language]?
      (p.express(context) for p in @alternates[context.language][0]).join("")
    else
      (p.express(context) for p in @alternates.default[0]).join("")

  matchFragment: (language, line, testLine) ->
    for parts in @alternates.default
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

  toLocalization: (localization) ->
    collectParts = (parts) ->
      locParts = []
      for p in parts when p.toLocalization?
        fragment = p.toLocalization(localization)
        locParts.push fragment if fragment?
      locParts.join ''

    switch @alternates.default.length
      when 0 then return
      when 1
        speech = collectParts(@alternates.default[0])
        unless localization.speech[speech]?
          localization.speech[speech] = {}
      else
        speeches = ( collectParts(a) for a in @alternates.default )
        speeches = speeches.join('|')
        unless localization.speech[speeches]?
          localization.speech[speeches] = {}
