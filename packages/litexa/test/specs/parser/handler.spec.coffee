###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

Utils = require('@src/parser/utils').lib
{assert, expect} = require('chai')

describe 'parses request data', ->
  global.litexa = {
    extendedEventNames: [],
    overridableFunctions: {
      generateDBKey: () -> 'key'
    }
  }
  global.extensionEvents = {}
  global.extensionRequests = {}

  # needs to come after injecting globals
  Handler = require('@src/parser/handler')

  it 'installs extensions before parsing', ->
    global.initializeExtensionObjects = ->
        global.extensionRequests['testExtension'] = {
          testIntent: (req) -> 
            console.log('installing intent')
        }

    resp = Handler.handlerSteps.parseRequestData({
      settings: { resetOnLaunch: true },
      event: { request: { type: 'testIntent' }, session: { attributes: {} } },
      request: { type: 'testIntent' },
      db: { 
        read: () -> , 
        write: () -> 
      }
    })

    