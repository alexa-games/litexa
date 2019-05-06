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

import {inspect} from 'util';

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

function addNumbers(...numbers: number[]): number {
    // tslint:disable:no-console
    console.log(`the arguments are ${numbers}`);
    return Array.from(numbers).reduce((accumulator: number, num: number) => accumulator + num, 0);
}

export {
    todayName,
    addNumbers
};
