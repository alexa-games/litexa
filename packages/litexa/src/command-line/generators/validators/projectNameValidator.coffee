###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

module.exports = (proposedName) ->
  if proposedName.length < 5
    throw new Error 'A project name should be at least 5 characters.'

  invalidCharacters = /[^a-zA-Z0-9_\-]/g
  match = invalidCharacters.exec proposedName
  if match?
    throw new Error "The character '#{match[0]}' is invalid. You can use letters, numbers, hyphen or underscore characters."

  true
