/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
