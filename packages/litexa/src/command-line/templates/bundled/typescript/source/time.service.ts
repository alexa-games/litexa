/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

export interface TimeService {
    serverTimeGetDay(date?: Date): number;
}

export const Time: TimeService = {
    serverTimeGetDay: (date = new Date()): number => {
        return date.getDay();
    }
};
