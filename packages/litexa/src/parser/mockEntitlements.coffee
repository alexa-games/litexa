###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

module.exports.fetchAll = (event, stateContext, after) ->
  unless stateContext.inSkillProducts.inSkillProducts?
    stateContext.inSkillProducts.inSkillProducts = []
  after()
