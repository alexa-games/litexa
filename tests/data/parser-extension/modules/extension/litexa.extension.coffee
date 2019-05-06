
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


class ExtensionClass
  constructor: (@testData) ->

  toLambda: (output, indent, options) ->
    output.push "#{indent}context.db.write('number', #{@testData});"
    output.push "#{indent}context.say.push('#{@testData}');"

module.exports = (options, lib) ->
  return {
    language: {
      statements: {
        NewExtendedStatement: {
          parser: """
            NewExtendedStatement
            = "extendedStatement" ___ data:Integer {
              pushCode(location(), new lib.ExtensionClass(data));
            }
          """
        }
      }
      lib: {
        ExtensionClass: ExtensionClass
      }
    }
  }
