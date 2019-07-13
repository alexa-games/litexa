###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

Test.expect "Gadget Directives to be validated", ->
  Test.directives "inputHandler", anyButtonHandler()
  Test.directives "setLight", pulseButtons()
