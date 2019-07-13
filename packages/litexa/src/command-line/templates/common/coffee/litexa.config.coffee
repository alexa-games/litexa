###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

module.exports =
  name: '{name}'
  deployments:
    development:
      module: '@litexa/deploy-aws'
      S3BucketName: null
      askProfile: null
      awsProfile: null
  extensionOptions: {}
