###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

Test.expect "stuff to work", ->
  Test.equal typeof(todayName()), 'string'
  Test.check -> addNumbers(1, 2, 3) == 6
  Test.report "today is #{todayName()}"
