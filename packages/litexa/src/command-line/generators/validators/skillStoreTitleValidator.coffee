
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


module.exports = (proposedName) ->
  if !proposedName
    throw new Error 'Your skill store title cannot be empty.'
  # @TODO, add more SMAPI based restrictions here
  invalidCharacters = /[^a-zA-Z0-9'-_ ]/g
  match = invalidCharacters.exec proposedName
  if match?
    throw new Error "The character #{match[0]} is invalid. You can use letters, numbers, the
      possessive apostrophe, spaces and hyphen or underscore characters."

  invalidWords = /(alexa|echo|computer|amazon)/i
  match = invalidWords.exec proposedName
  if match?
    throw new Error "Invalid word #{match[0]} used in skill's store title. You cannot use any of
      these words: alexa, echo, computer, amazon"

  true
