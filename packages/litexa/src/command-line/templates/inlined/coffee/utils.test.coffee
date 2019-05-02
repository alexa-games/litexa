Test.expect "stuff to work", ->
  Test.equal typeof(todayName()), 'string'
  Test.check -> addNumbers(1, 2, 3) == 6
  Test.report "today is #{todayName()}"
