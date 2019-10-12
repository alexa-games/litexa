###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

getNumbers = -> [3, 5, 8, 9]

getNames = ->
  driver: 'bob'
  artillery: 'tim'
  hacker: 'mary'

processJobAsync = (name) ->
  await new Promise (resolve, reject) ->
    setTimeout (-> resolve("the #{name}")), 50
