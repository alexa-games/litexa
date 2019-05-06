
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

class lib.PurchaseStatement
  constructor: (referance_name) ->
    @referance_name = referance_name

  toLambda: (output, indent, options) ->
    # TODO: add warning if context.directives is not empty
    # purchase directive must be the only directive in the response
    output.push "#{indent}buildPurchaseDirective(context, \"#{@referance_name}\");"

class lib.CancelPurchaseStatement
  constructor: (referance_name) ->
    @referance_name = referance_name

  toLambda: (output, indent, options) ->
    # TODO: add warning if context.directives is not empty
    # purchase directive must be the only directive in the response
    output.push "#{indent}buildCancelPurchaseDirective(context, \"#{@referance_name}\");"
