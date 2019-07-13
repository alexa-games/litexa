/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

import {inspect} from 'util';
import {Time} from '../services/time.service';
import logger from './logger';

const ORDERED_DAYS_OF_WEEK = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
];

export function todayName(timeService = Time): string {
    const day: number = timeService.serverTimeGetDay();
    return ORDERED_DAYS_OF_WEEK[day];
}

export function addNumbers(...numbers: number[]): number {
    logger.info(`the arguments are ${inspect(numbers)}`);
    return Array.from(numbers).reduce((accumulator: number, num: number) => accumulator + num, 0);
}
