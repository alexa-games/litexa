module.exports = (options, lib) ->
  language: 
    statements: 

      "InlineStatement":
        parser: "InlineStatement = 'inlineStatement' ___ n:Number {
          pushCode(location(), new lib.InlineStatement(n));
        }"

    lib: 
      InlineStatement: InlineStatement


class InlineStatement
  constructor: (@number) ->
  
  toLambda: (output, indent, options) ->
    output.push "#{indent}context.say.push('Inline statement said #{@number}.');"
    output.push "#{indent}console.log('inline statement value: #{@number}');"