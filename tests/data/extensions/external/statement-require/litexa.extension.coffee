module.exports = (options, lib) ->
  language:
    statements:
      "RequireStatement":
        parser: "RequireStatement = 'requireStatement' ___ n:Number {
          pushCode(location(), new lib.RequireStatement(n));
        }"

    lib:
      RequireStatement: RequireStatement


class RequireStatement
  constructor: (@number) ->

  toLambda: (output, indent, options) ->
    output.push "#{indent}(require('statement-require/stuff')).statement(context, #{@number});"
