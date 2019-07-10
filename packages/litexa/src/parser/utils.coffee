
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