
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

  pushAlternate: (assetName) ->
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
    output.push "#{indent}context.musicCommand = { action: 'play', url: '#{@assetName.toURL(options.language)}' }"

  collectRequiredAPIs: (apis) -> apis['AUDIO_PLAYER']

class lib.StopMusic
  constructor: (@location) ->

  toString: "stopMusic"

  toLambda: (output, indent, options) ->
    output.push "#{indent}context.musicCommand = { action: 'stop' }"

  collectRequiredAPIs: (apis) -> apis['AUDIO_PLAYER']
