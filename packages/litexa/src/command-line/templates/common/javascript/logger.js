/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

import pino from 'pino';
import prettifier from 'pino-pretty';

const config = {
  name: '{name}-skill',
  level: process.env.LOGGER_LEVEL || 'debug',
  prettyPrint: {
    levelFirst: true
  },
  prettifier
};

const logger = pino(config);

export default logger;
