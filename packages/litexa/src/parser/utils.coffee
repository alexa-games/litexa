###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###
lib = module.exports.lib = {}

lib.replaceNewlineCharacters = (str, replacementCharacter) ->
  return "" unless str?
  str.replace(/\n/g, replacementCharacter)

lib.isEmptyContentString = (str) ->
  return str.trim().length == 0

lib.isFirstOrLastItemOfArray = (idx, arr) ->
  return 0 == idx or arr.length - 1 == idx

lib.cleanLeadingSpaces = (str) ->
  return str.replace /\n[ \t]+/g, '\n'

lib.cleanTrailingSpaces = (str) ->
  return str.replace /[ \t]+\n/g, '\n'

lib.dedupeNonNewlineConsecutiveWhitespaces = (str) ->
  return str.replace /[ \t][ \t]+/g, ' '

# Method that stringifies a function and normalizes the indentation.
lib.stringifyFunction = (func, indent = '') ->
  funcString = func.toString()
  return lib.normalizeIndentForStringifiedFunction(funcString, indent)

lib.normalizeIndentForStringifiedFunction = (funcString, indent) ->
  # First, let's check our stringified function's indent.
  indentMatch = funcString.match(/\n[ ]*/)
  if indentMatch?
    callbackIndent = indentMatch[0].length - 3 # 3 = newline char (1) + second line indentation (2)

    # normalize the indent
    indentRegex = new RegExp("\n {#{callbackIndent}}", 'g')
    funcString = funcString.replace(indentRegex, "\n#{indent}")
    # normalize the function/parentheses spacing (varies between different OSs)
    funcString = funcString.replace(/function\s+\(\)/, 'function()')
  else
    return funcString
