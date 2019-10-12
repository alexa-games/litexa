###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

module.exports = class DBInterface
  constructor: ->
    @variables = {}
    @written = false
    @initialized = false

  isInitialized: ->
    @initialized

  initialize: ->
    @initialized = true

  read: (name) ->
    @variables[name]

  write: (name, value) ->
    @written = true
    @variables[name] = value

  finalize: (cb) ->
    setTimeout cb, 1
