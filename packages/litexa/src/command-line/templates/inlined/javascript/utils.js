/*
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved. 
 * These materials are licensed as "Restricted Program Materials" under the Program Materials 
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service. 
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html. 
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized 
 * terms not defined in this file have the meanings given to them in the Agreement. 
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

'use strict';

function todayName() {
  let day;
  day = (new Date).getDay();
  return ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][day];
}

function addNumbers(...numbers) {
  let i, len, num, result;
  console.log(`the arguments are ${numbers}`);
  result = 0;
  for (i = 0, len = numbers.length; i < len; i++) {
    num = numbers[i];
    result += num;
  }
  return result;
}

