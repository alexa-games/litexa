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
