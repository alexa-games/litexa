###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

module.exports =
  name: '{name}'
  useSessionAttributesForPersistentStore: false
  deployments:
    development:
      module: '@litexa/deploy-aws'
      s3Configuration:
        bucketName: null
      askProfile: null
      awsProfile: null
  extensionOptions: {}
