###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

db =
  fetchDB: ({ identity, dbKey, sessionAttributes, fetchCallback }) ->
    store = sessionAttributes.litexa ? {}
    sessionAttributes.litexa = store

    databaseObject =
      isInitialized: -> return true
      read: (key) -> return store[key]
      write: (key, value) -> store[key] = value
      finalize: (cb) ->
        setTimeout cb, 1

    setTimeout (-> fetchCallback null, databaseObject), 1