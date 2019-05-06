
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


fs = require 'fs'
path = require 'path'

module.exports = (context, logger, AWS) ->

  config = null

  jsonCredentialsFile = path.join context.projectConfig.root, 'aws-config.json'
  try
    require('./local-cache').loadCache(context)
  catch err
    # it's ok for now, not everyone caches

  try
    if fs.existsSync jsonCredentialsFile
      credentials = JSON.parse fs.readFileSync(jsonCredentialsFile, 'utf-8')
      credentials = credentials[context.deploymentName]
      unless credentials?
        throw "No AWS credentials exist for the `#{context.deploymentName}` deployment target.
          See @litexa/deploy-aws/readme.md for details on your aws-config.json."
      config = new AWS.Config(credentials)
      logger.log "loaded AWS config from #{jsonCredentialsFile}"
  catch err
    throw "Failed to load #{jsonCredentialsFile}: #{err}"

  unless config?
    profile = context.deploymentOptions.awsProfile ? "default"
    credentials = new AWS.SharedIniFileCredentials {
      profile: profile
    }

    unless credentials.secretAccessKey?
      throw "Failed to load the AWS profile #{profile}.
        You need to ensure that the aws-cli works with that
        profile before you can try again.
        Alternatively, you may want to add a local authorization
        with a aws-config.json file? See
        @litexa/deploy-aws/readme.md for details."

    config = new AWS.Config()
    config.credentials = credentials
    unless config.region?
      config.region = 'us-east-1'

    logger.log "loaded AWS profile #{profile}"

  AWS.config = config
  context.AWSConfig = config
