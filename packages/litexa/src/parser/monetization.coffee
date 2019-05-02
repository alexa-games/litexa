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
