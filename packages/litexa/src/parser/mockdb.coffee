###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

DBInterface = require('./dbInterface.coffee')


module.exports = class MockDB
  constructor: ->
    @identities = {}

  reset: ->
    @identities = {}

  getVariables: (identity) ->
    DBKEY = "#{identity.deviceId}|#{identity.requestAppId}"
    @identities[DBKEY] = @identities[DBKEY] ? {}
    return JSON.parse(JSON.stringify(@identities[DBKEY]))

  setVariables: (identity, data) ->
    DBKEY = "#{identity.deviceId}|#{identity.requestAppId}"
    @identities[DBKEY] = JSON.parse(JSON.stringify(data))

  fetchDB: ({ identity, fetchCallback }) ->
    DBKEY = "#{identity.deviceId}|#{identity.requestAppId}"
    database = new DBInterface
    if DBKEY of @identities
      database.initialize()
      database.variables = JSON.parse(JSON.stringify(@identities[DBKEY]))

    database.finalize = (finalizeCallback) =>
      # enable this to test the concurrency loop in the handler
      #database.repeatHandler = Math.random() > 0.7
      unless database.repeatHandler
       @identities[DBKEY] = JSON.parse(JSON.stringify(database.variables))
      setTimeout finalizeCallback, 1

    setTimeout (->fetchCallback(null, database)), 1
