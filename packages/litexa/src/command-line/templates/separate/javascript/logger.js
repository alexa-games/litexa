/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const pino = require('pino');
const prettifier = require('pino-pretty');

const config = {
  name: 'template_generation-skill',
  level: process.env.LOGGER_LEVEL || 'debug',
  prettyPrint: {
    levelFirst: true
  },
  prettifier
};

const logger = pino(config);

module.exports = logger;
