###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

module.exports = (stringTemplate, templateValues) ->
  data = stringTemplate
  for key, value of templateValues
    match = ///\{#{key}\}///g
    data = data.replace(match, value)

  data
