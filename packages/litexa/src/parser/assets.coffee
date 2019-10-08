###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

path = require('path')
{ ParserError } = require('./errors.coffee').lib

lib = module.exports.lib = {}

class lib.AssetName
  constructor: (@location, @name, @type, @skill, @localFile = true) ->

  isAssetName: true

  localizedFilename: (language, filename) ->
    unless @skill.projectInfo
      throw new Error "assetName cannot be localized because skill has no project info"
    unless language?
      if @skill.strictMode
        throw new Error "missing language in localizedFilename"
      else
        console.error "missing language in localizedFilename"
      language = 'default'
    files = @skill.projectInfo.languages[language]?.assets?.files
    convertedFiles = @skill.projectInfo.languages[language]?.convertedAssets?.files
    if files? or convertedFiles?
      if files? and filename in files
        return "#{language}/#{filename}"

      if convertedFiles and filename in convertedFiles
        return "#{language}/#{filename}"

      if language == 'default'
        throw new ParserError @location, "couldn't find an asset with the name #{filename} in the project info"
      else
        return @localizedFilename 'default', filename
    else
      # unsupported language?
      if language == 'default'
        throw new Error "no file list available somehow, while looking for #{filename}"
      else
        return @localizedFilename 'default', filename


  toURL: (language) ->
    unless @localFile
      return "#{@name}"

    filename = @localizedFilename(language, "#{@name}.#{@type}")
    "#{filename}"

  toURLFunction: (language) ->
    unless @localFile
      return "#{@name}"

    filename = @localizedFilename(language, "#{@name}.#{@type}")
    """ litexa.assetsRoot + "#{filename}" """

  toURLVariant: (language, variant) ->
    unless @localFile
      return "#{@name}"

    try
      filename = @localizedFilename(language, "#{@name}-#{variant}.#{@type}")
    catch
      filename = null
    unless filename?
      # support fallback to non-variant
      try
        filename = @localizedFilename(language, "#{@name}.#{@type}")
      catch
        console.log @skill.projectInfo.languages.default
        throw new Error "Couldn't find variant file, nor the common version of #{@name}.#{@type}, #{variant}"
    "#{filename}"

  toURLVariantFunction: (language, variant) ->
    unless @localFile
      return """ "#{@name}" """

    try
      filename = @localizedFilename(language, "#{@name}-#{variant}.#{@type}")
    catch
      filename = @localizedFilename(language, "#{@name}.#{@type}")
    """ litexa.assetsRoot + "#{filename}" """


  hasVariant: (language, variant) ->
    unless @localFile
      return true

    try
      @localizedFilename(language, "#{@name}-#{variant}.#{@type}")
      return true
    catch
      return false

  toString: ->
    unless @localFile
      return "#{@name}"

    "#{@name}.#{@type}"

  toSSMLFunction: (language) ->
    switch @type
      when 'mp3'
        if @localFile
          return """ "<audio src='" + litexa.assetsRoot + "#{@toURL(language)}'/>" """
        else
          return """ "<audio src='#{@toURL(language)}'/>" """
      else
        throw new ParserError @location, "Asset type #{@.toString()} had no
          obvious way of being expressed in SSML"

  toSSML: (language) ->
    switch @type
      when 'mp3'
        return "<audio src='#{@toURL(language)}'/>"
      else
        throw new ParserError @location, "Asset type #{@.toString()} had no
          obvious way of being expressed in SSML"

  toRegex: ->
    switch @type
      when 'mp3'
        #line = literalRegex("<audio src='#{@toURL()}'/>")
        line = literalRegex("<#{@toString()}>")
        return line
      else
        throw new ParserError @location, "Asset type #{@.toString()} had no
          obvious way of being expressed in SSML, and so can't be tested"

class lib.FileFunctionReference
  constructor: (@location, @filename, @functionName) ->

  isFileFunctionReference: true

lib.parseJsonFile = (location, filename, skill) ->
  lang = location?.language ? 'default'
  jsonPath = path.join skill.projectInfo.languages["#{lang}"].code.root, filename

  try
    return require jsonPath
  catch
    throw new ParserError location, "Unable to find #{filename} at #{jsonPath}. Make sure to specify
      a path relative to the litexa folder."
