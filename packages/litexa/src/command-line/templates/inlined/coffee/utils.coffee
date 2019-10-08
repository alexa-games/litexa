###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

todayName = ->
  day = (new Date).getDay()
  return [ 'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday' ][day]

addNumbers = (...numbers) ->
  console.log "the arguments are #{numbers}"
  result = 0
  for num in numbers
    result += num
  return result
