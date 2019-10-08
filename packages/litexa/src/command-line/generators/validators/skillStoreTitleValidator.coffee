###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
