###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

lib = module.exports.lib = {}

{ ParserError } = require('./errors.coffee').lib


literalRegex = (line) ->
  line = line.replace /\./g, '\\.'
  line = line.replace /\//g, '\\/'
  line = line.replace /\\/g, '\\'
  line = line.replace /\-/g, '\\-'
  return line


class lib.SoundEffect
  constructor: (@location, assetName) ->
    @alternates = [assetName]

  isSoundEffect: true

  pushAlternate: (location, assetName) ->
    unless assetName.isAssetName
      throw new ParserError assetName.location, "Alternate type mismatch,
        expecting an audio asset here, saw a #{assetName.constructor?.name} instead"
    @alternates.push assetName

  toLambda: (output, indent, options) ->
    if @alternates.length > 1
      sayKey = require('./sayCounter').get()
      output.push "#{indent}switch(pickSayString(context, #{sayKey}, #{@alternates.length})) {"
      for alt, idx in @alternates
        if idx == @alternates.length - 1
          output.push "#{indent}  default:"
        else
          output.push "#{indent}  case #{idx}:"
        line = alt.toSSMLFunction(options.language)
        if line and line != '""'
          output.push "#{indent}    context.say.push( #{line} );"
        output.push "#{indent}    break;"
      output.push "#{indent}}"
    else
      line = @alternates[0].toSSMLFunction(options.language)
      output.push "#{indent}context.say.push( #{line} );"

  toSSML: (language) ->
    @alternates[0].toSSML(language)

  matchFragment: (language, line, asTestLine) ->
    for name in @alternates
      if asTestLine
        unless name.testRegex?
          regexText = "((<#{literalRegex(name.toString())}>)|(<audio src='.*#{literalRegex(name.toString())}'/>))"
          name.testRegex = new RegExp(regexText, '')
        regex = name.testRegex
      else
        unless name.regex?
          regexText = "(#{literalRegex(name.toSSML(language))})"
          name.regex = new RegExp(regexText, '')
        regex = name.regex

      match = regex.exec(line)
      continue unless match?
      continue unless match[0].length > 0

      result =
        offset: match.index
        reduced: line.replace regex, ''
        part: @
        removed: match[0]
        slots: {}
        dbs: {}

      return result

    return null


class lib.PlayMusic
  constructor: (@location, @assetName) ->

  toString: "playMusic #{@assetName}"

  toLambda: (output, indent, options) ->
    if @assetName.localFile
      output.push "#{indent}context.musicCommand = { action: 'play', url: #{@assetName.toURLFunction(options.language)} }"
    else
      output.push "#{indent}context.musicCommand = { action: 'play', url: '#{@assetName}' }"

  collectRequiredAPIs: (apis) ->
    apis['AUDIO_PLAYER'] = true

class lib.StopMusic
  constructor: (@location) ->

  toString: "stopMusic"

  toLambda: (output, indent, options) ->
    output.push "#{indent}context.musicCommand = { action: 'stop' }"

  collectRequiredAPIs: (apis) ->
    apis['AUDIO_PLAYER'] = true
