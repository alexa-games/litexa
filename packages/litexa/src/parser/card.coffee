
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

{ AssetName } = require('./assets.coffee').lib
{ ParserError } = require('./errors.coffee').lib

class lib.Card
  constructor: (@location, @title, @content, @imageAssetName) ->

  isCard: true

  pushAttribute: (location, key, value) ->
    switch key
      when 'repeatSpeech'
        if value
          @repeatSpeech = true
      when 'content'
        @content = value
      when 'image'
        unless value.isAssetName or value.isVariableReference
          throw new ParserError location, "the `image` key expects an asset name or variable reference value, e.g. something.jpg or myVariable"
        @imageAssetName = value
      else
        throw new ParserError location, "Unknown attribute name in #{key}:#{value}, expected `content` or `image`"

  toString: ->
    "#{@title}: #{@content}"

  toLambda: (output, indent, options) ->
    output.push "#{indent}context.card = {"
    if @title
      output.push "#{indent}  title: #{@title.toExpression(options)},"
    if @content
      output.push "#{indent}  content: #{@content.toExpression(options)},"
    else if @repeatSpeech
      output.push "#{indent}  repeatSpeech: true"
    output.push "#{indent}};"
    if @imageAssetName?
      output.push "#{indent}context.card.imageURLs = {"
      url = null
      for variant in ["cardSmall", "cardLarge"]
        if @imageAssetName.isAssetName
          url = @imageAssetName.toURLVariantFunction options.language, variant
        else
          name = @imageAssetName.toExpression(options)
          url = "litexa.assetsRoot + \"#{options.language}/\" + #{name}"
        output.push "#{indent}  #{variant}: #{url}, "

      output.push "#{indent}};"

  hasStatementsOfType: (types) -> 'card' in types
