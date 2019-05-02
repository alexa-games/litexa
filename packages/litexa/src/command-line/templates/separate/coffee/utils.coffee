{inspect} = require 'util'
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

todayName = (date = new Date()) ->
  day =  date.getDay();
  ORDERED_DAYS_OF_WEEK[day]

addNumbers = (...numbers) ->
  logger.info "the arguments are #{inspect(numbers)}"
  sum = (accumulator, number) -> accumulator + number
  Array.from(numbers).reduce(sum, 0)

module.exports =
  todayName: todayName
  addNumbers: addNumbers
