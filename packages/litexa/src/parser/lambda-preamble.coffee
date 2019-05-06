
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


AWS = require('aws-sdk')
AWS.config.update({region: "us-east-1"})

#require('coffeescript').register()

dynamoDocClient = new AWS.DynamoDB.DocumentClient {
  convertEmptyValues: true
  service: new AWS.DynamoDB {
      maxRetries: 5
      retryDelayOptions:
        base: 150
      paramValidation: false
      httpOptions:
        agent: new (require 'https').Agent({ keepAlive: true })
    }
}

cloudWatch = new AWS.CloudWatch({
  httpOptions:
    agent: new (require 'https').Agent({ keepAlive: true })
})

db =
  fetchDB: (identity, fetchCallback) ->

    if true
      tableName = process?.env?.dynamoTableName
      unless tableName?
        throw new Error "Missing dynamoTableName in the lambda environment. Please set it to the
          DynamoDB table you'd like to use, in the same AWS account."

      # we're using per application tables, already partitioned by deployment
      # so all we need here is the device identifier
      DBKEY = "#{identity.deviceId}"

      params =
        Key:
          userId: DBKEY
        TableName: tableName
        ConsistentRead: true

      #console.log 'fetching from DynamoDB : ' + JSON.stringify(params)
      dynamoDocClient.get params, (err, data) ->
        if err
          console.error "Unable to read from dynamo
            Request was: #{JSON.stringify(params, null, 2)}
            Error was: #{JSON.stringify(err, null, 2)}"
          fetchCallback(err, null)
        else
          #console.log "fetched from DB", JSON.stringify(data.Item)
          wasInitialized = data.Item?.data?
          backing = data.Item?.data ? {}
          if data.Item?
            clock = data.Item.clock ? 0
            lastResponseTime = data.Item.lastResponseTime
          else
            clock = null
            lastResponseTime = 0
          dirty = false
          databaseObject =
            isInitialized: -> return wasInitialized
            initialize: -> wasInitialized = true
            read: (key, markDirty) ->
              if markDirty
                dirty = true
              return backing[key]
            write: (key, value) ->
              backing[key] = value
              dirty = true
              return
            finalize: (finalizeCallback) ->
              unless dirty
                return setTimeout (->finalizeCallback()), 1

              params =
                TableName : tableName
                Item:
                  userId: DBKEY
                  data: backing

              if true
                if clock?
                  # item existed, conditionally replace it
                  if clock > 0
                    params.ConditionExpression = "clock = :expectedClock"
                    params.ExpressionAttributeValues =
                      ":expectedClock": clock
                  params.Item.clock = clock + 1
                else
                  # item didn't exist, conditionally create it
                  params.ConditionExpression = "attribute_not_exists(userId)"
                  params.Item.clock = 0

              dispatchSave = ->
                #console.log "sending #{JSON.stringify(params)} to dynamo"
                params.Item.lastResponseTime = (new Date()).getTime()
                dynamoDocClient.put params, (err, data) ->
                  if err?.code == 'ConditionalCheckFailedException'
                    console.log "DBCONDITION: #{err}"
                    databaseObject.repeatHandler = true
                    err = null
                  else if err?
                    console.error "DBWRITEFAIL: #{err}"

                  finalizeCallback err, params

              space = (new Date()).getTime() - lastResponseTime
              requiredSpacing = databaseObject.responseMinimumDelay ? 500
              if space >= requiredSpacing
                dispatchSave()
              else
                wait = requiredSpacing - space
                console.log "DELAYINGRESPONSE Spacing out #{wait}, #{(new Date()).getTime()} #{lastResponseTime}"
                setTimeout dispatchSave, wait

          fetchCallback(null, databaseObject)

    else
      mock = {}
      databaseObject =
        isInitialized: -> return true
        read: (key) -> return mock[key]
        write: (key, value) -> mock[key] = value
        finalize: (cb) ->
          setTimeout cb, 1

      setTimeout (-> fetchCallback null, databaseObject), 1

Entitlements =
  fetchAll: (event, stateContext, after) ->
    try
      https = require('https')
    catch
      # no https means no access to internet, can't do this
      console.log "skipping fetchEntitlements, no interface present"
      after()
      return

    apiEndpoint = "api.amazonalexa.com"
    apiPath     = "/v1/users/~current/skills/~current/inSkillProducts"
    token = "bearer " + event.context.System.apiAccessToken
    language = "en-US"

    options =
      host: apiEndpoint
      path: apiPath
      method: 'GET'
      headers:
        "Content-Type"      : 'application/json'
        "Accept-Language"   : language
        "Authorization"     : token

    req = https.get options, (res) =>
      res.setEncoding("utf8")

      if (res.statusCode != 200)
        after "failed to fetch entitlements, status code was #{res.statusCode}"
        return

      returnData = ""
      res.on 'data', (chunk) =>
        returnData += chunk

      res.on 'end', () =>
        stateContext.inSkillProducts = JSON.parse(returnData)
        stateContext.db.write "__inSkillProducts", stateContext.inSkillProducts
        after()

    req.on 'error', (e) ->
      after 'Error calling InSkillProducts API: '
