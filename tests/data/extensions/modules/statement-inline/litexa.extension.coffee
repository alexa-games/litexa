
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
