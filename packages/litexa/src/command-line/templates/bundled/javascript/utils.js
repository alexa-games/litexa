'use strict';

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

export function todayName(timeService = Time) {
    const day = timeService.serverTimeGetDay();
    return ORDERED_DAYS_OF_WEEK[day];
}

export function addNumbers(...numbers) {
    logger.info(`the arguments are ${inspect(numbers)}`);
    return Array.from(numbers).reduce((accumulator, number) => accumulator + number, 0);
}
