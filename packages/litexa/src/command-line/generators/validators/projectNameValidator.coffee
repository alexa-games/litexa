
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
  if proposedName.length < 5
    throw new Error 'A project name should be at least 5 characters.'

  invalidCharacters = /[^a-zA-Z0-9_\-]/g
  match = invalidCharacters.exec proposedName
  if match?
    throw new Error "The character '#{match[0]}' is invalid. You can use letters, numbers, hyphen or underscore characters."

  true
