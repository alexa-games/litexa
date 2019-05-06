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

let {inspect} = require('util');
let logger = require('./logger');

const ORDERED_DAYS_OF_WEEK = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
];

function todayName(date = new Date()) {
    const day =  date.getDay();
    return ORDERED_DAYS_OF_WEEK[day];
}

function addNumbers(...numbers) {
    logger.info(`the arguments are ${inspect(numbers)}`);
    return Array.from(numbers).reduce((accumulator, number) => accumulator + number, 0);
}

module.exports = {
    todayName,
    addNumbers
};
