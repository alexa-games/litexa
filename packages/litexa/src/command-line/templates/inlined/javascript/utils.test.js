'use strict';

Test.expect("stuff to work", function() {
  Test.equal(typeof (todayName()), 'string');
  Test.check(function() {
    return addNumbers(1, 2, 3) === 6;
  });
  return Test.report(`today is ${todayName()}`);
});
