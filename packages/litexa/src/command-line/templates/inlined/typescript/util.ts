/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
