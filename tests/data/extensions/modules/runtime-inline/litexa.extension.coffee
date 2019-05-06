
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


module.exports = (options, lib) ->
  compiler: 
    validIntentNames: [ 'TotallyNot.RealIntent' ]

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
