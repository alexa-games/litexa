
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

class lib.BuyInSkillProductStatement
  constructor: (referenceName) ->
    @referenceName = referenceName

  toLambda: (output, indent, options) ->
    # @TODO: add warning if context.directives is not empty
    # purchase directive must be the only directive in the response
    output.push "#{indent}buildBuyInSkillProductDirective(context, \"#{@referenceName}\");"

class lib.CancelInSkillProductStatement
  constructor: (referenceName) ->
    @referenceName = referenceName

  toLambda: (output, indent, options) ->
    # @TODO: add warning if context.directives is not empty
    # purchase directive must be the only directive in the response
    output.push "#{indent}buildCancelInSkillProductDirective(context, \"#{@referenceName}\");"


class lib.UpsellInSkillProductStatement
  constructor: (referenceName) ->
    @referenceName = referenceName
    @attributes = { message: '' }

  toLambda: (output, indent, options) ->
    # @TODO: add warning if context.directives is not empty
    # purchase directive must be the only directive in the response
    output.push "#{indent}buildUpsellInSkillProductDirective(context, \"#{@referenceName}\", \"#{@attributes.message}\");"

  pushAttribute: (location, key, value) ->
    supportedKeys = [ 'message' ]

    unless key in supportedKeys
      throw new lib.ParserError(location, "Attribute '#{key}' not supported > supported keys are: #{JSON.stringify(supportedKeys)}")

    @attributes[key] = value
