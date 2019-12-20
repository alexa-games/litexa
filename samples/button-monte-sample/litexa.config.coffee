###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

module.exports =
  name: 'button-monte-sample'
  deployments:
    development:
      module: '@litexa/deploy-aws'
      s3Configuration:
        bucketName: null
      askProfile: null
      awsProfile: null
  extensionOptions: {}
  # there is no built-in Litexa support for this directive,
  # so declaring it here
  directiveWhitelist: [
    "GadgetController.SetLight"
  ]
