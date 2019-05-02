{todayName} = require './components/utils'
{Time} = require './services/time.service'

module.exports =
  todayName: todayName
  getDay: Time.serverTimeGetDay
