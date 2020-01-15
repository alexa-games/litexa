###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

{expect} = require 'chai'
sinon = require 'sinon'

AWS = require 'aws-sdk'
assetsHandler = require '../src/assets'
awsConfigHandler = require '../src/aws-config'
s3Utils = require '../src/utils/s3Utils'

describe 'Upload Assets', ->
  logger = undefined
  context = undefined

  awsS3Stub = undefined
  awsConfigHandleStub = undefined
  collectUploadInfoStub = undefined
  listBucketAndUploadAssetsStub = undefined
  prepareBucketStub = undefined
  validateS3BucketNameStub = undefined
  validateS3PathNameStub = undefined

  beforeEach ->
    logger =
      log: -> undefined
      error: -> undefined

    context =
      projectConfig:
        root: 'myProjectRoot'
      skill:
        projectInfo:
          name: 'myProjectName'
          variant: 'myProjectVariant'
      deploymentName: 'myDeploymentName'
      deploymentOptions:
        awsProfile: 'myAwsProfile'
        s3Configuration:
          bucketName: 'myBucketName'
      artifacts:
        save: -> undefined

    awsS3Stub = sinon.stub(AWS, 'S3').returns({ config: { region: undefined } })
    awsConfigHandleStub = sinon.stub(awsConfigHandler, 'handle').returns(undefined)
    collectUploadInfoStub = sinon.stub(s3Utils, 'collectUploadInfo').returns(undefined)
    listBucketAndUploadAssetsStub = sinon.stub(s3Utils, 'listBucketAndUploadAssets').returns(undefined)
    prepareBucketStub = sinon.stub(s3Utils, 'prepareBucket').returns({ then: -> { then: -> { catch: -> undefined } } })
    validateS3BucketNameStub = sinon.stub(s3Utils, 'validateS3BucketName').returns(undefined)
    validateS3PathNameStub = sinon.stub(s3Utils, 'validateS3PathName').returns(undefined)

  afterEach ->
    awsS3Stub.restore()
    awsConfigHandleStub.restore()
    collectUploadInfoStub.restore()
    listBucketAndUploadAssetsStub.restore()
    prepareBucketStub.restore()
    validateS3BucketNameStub.restore()
    validateS3PathNameStub.restore()

  describe '#deploy()', ->
    it 'happy path', ->
      assetsHandler.deploy context, logger
