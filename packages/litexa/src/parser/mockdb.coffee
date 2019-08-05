
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
