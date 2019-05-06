
###

 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved.
 * These materials are licensed as "Restricted Program Materials" under the Program Materials
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service.
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html.
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized
 * terms not defined in this file have the meanings given to them in the Agreement.
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

###


{inspect} = require 'util'
{Time} = require '../services/time.service'
logger = require './logger'

ORDERED_DAYS_OF_WEEK = [
  'Sunday'
  'Monday'
  'Tuesday'
  'Wednesday'
  'Thursday'
  'Friday'
  'Saturday'
]

todayName = (timeService = Time) ->
  day = timeService.serverTimeGetDay()
  ORDERED_DAYS_OF_WEEK[day]

addNumbers = (...numbers) ->
  logger.info "the arguments are #{inspect(numbers)}"
  sum = (accumulator, number) -> accumulator + number
  Array.from(numbers).reduce(sum, 0)

module.exports =
  todayName: todayName
  addNumbers: addNumbers
