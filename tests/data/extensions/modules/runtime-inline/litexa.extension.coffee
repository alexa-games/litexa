###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

module.exports = (options, lib) ->
  compiler:
    validEventNames: [ 'TotallyNot.RealIntent' ]

  runtime:
    apiName: "RuntimeInline"
    source: runtime.toString()


runtime = (context) ->
  console.log "Runtime inline was constructed"

  myData =
    greeting: "Hello world. love, runtime inline"

  return
    userFacing:
      secret: 13
      hello: ->
        await new Promise (resolve, reject) ->
          done = ->
            resolve("runtime says, #{myData.greeting}.")
          setTimeout done, 100

    events:
      afterStateMachine: ->
        await new Promise (resolve, reject) ->
          done = ->
            context.say.push "Runtime inline here, after state machine."
            console.log "Runtime inline peeping after state machine"
            resolve()
          setTimeout done, 100

      beforeFinalResponse: (response) ->
        response.flags = response.flags ? {}
        response.flags.runtimeInlineApproved = true
        console.log "Runtime inline checked final response"

    requests:
      'SYSTEM.NotRealIntent': (request) ->
        console.log "psst, saw #{JSON.stringify request}"
