###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
