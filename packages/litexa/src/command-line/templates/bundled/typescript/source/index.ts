/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

import * as utils from './components/utils';
import {Time} from './services/time.service';

const litexaFunctions = {
    todayName: utils.todayName,
    getDay: Time.serverTimeGetDay
};

export = litexaFunctions;
