###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

skills = require('./skill.coffee')

if window?
  window.litexa = window.litexa ? {}
  window.litexa.files = window.litexa.files ? {}
  for k, v of skills
    window.litexa[k] = v
else
  self.litexa = self.litexa ? {}
  self.litexa.files = self.litexa.files ? {}
  for k, v of skills
    self.litexa[k] = v
