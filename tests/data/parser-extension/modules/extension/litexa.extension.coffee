###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
