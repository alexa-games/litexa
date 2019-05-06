
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


class exports.LocalizationContext
  constructor: ->

  pushDialog: (line) ->
    @dialog = @dialog ? []
    @dialog.push line

  pushOption: (key, context) ->
    @options = @options ? {}
    @options[key] = context

  registerVariable: (content) ->
    @variables = @variables ? []
    for v, i in @variables
      return i if v == content
    @variables.push content
    return @variables.length - 1

  hasContent: ->
    return true if @dialog?
    return true if @option?
    return true if @variables?
    return false
