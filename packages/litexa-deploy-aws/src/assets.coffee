###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

AWS = require 'aws-sdk'

configureAWS = require './aws-config'
s3Utils = require './utils/s3Utils'

module.exports = {
  deploy: (context, logger) ->
    logger.log "deploying assets"
    skill = context.skill
    s3Context = null

    await configureAWS.handle(context, logger, AWS)

    context.assetDeploymentStart = new Date

    bucketName = context.deploymentOptions?.S3BucketName ? context.deploymentOptions?.s3Configuration?.bucketName

    unless bucketName
      throw new Error "Found neither `S3BucketName` nor `s3Configuration.bucketName` in Litexa config for deployment
        target '#{context.deploymentName}'. Please use either setting to specify a bucket to create (if necessary) and deploy to."

    s3Utils.validateS3BucketName bucketName

    projectInfo = skill.projectInfo
    s3Context = {
      baseLocation: "#{projectInfo.name}/#{projectInfo.variant}"
      assets: {}
      listPage: 0
      bucketName: bucketName
    }

    s3Utils.validateS3PathName s3Context.baseLocation

    context.S3 = new AWS.S3 {
      params: {
        Bucket: bucketName
      }
    }

    region = context.S3.config.region
    s3Context.RESTRoot =  "https://s3.#{region}.amazonaws.com/#{bucketName}"
    if context.deploymentOptions?.overrideAssetsRoot?
      context.artifacts.save 'assets-root', context.deploymentOptions?.overrideAssetsRoot
    else
      context.artifacts.save 'assets-root', "#{s3Context.RESTRoot}/#{s3Context.baseLocation}/"

    us3UtilArgs = { s3Context, skillContext: context, logger }

    s3Utils.prepareBucket(us3UtilArgs)
    .then ->
      s3Utils.collectUploadInfo(us3UtilArgs)
    .then ->
      s3Utils.listBucketAndUploadAssets(us3UtilArgs)
    .catch (err) ->
      logger.error err
      throw "failed assets deployment"
}
