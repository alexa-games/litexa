###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

AWS = require('aws-sdk')
AWS.config.update({region: "us-east-1"})

cloudWatch = new AWS.CloudWatch({
  httpOptions:
    agent: new (require 'https').Agent({ keepAlive: true })
})


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
