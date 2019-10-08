###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

getAfterDelay = (number) ->
  if litexa.localTesting
    new Promise (resolve, reject) ->
      setTimeout (-> resolve("bob #{number}")), (50 + Math.random() * 100)
  else
    new Promise (resolve, reject) ->
      setTimeout (-> resolve("string #{number}")), 150
