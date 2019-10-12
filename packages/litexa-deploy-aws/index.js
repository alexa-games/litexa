#!/usr/bin/env node

/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */


var coffee = require('coffeescript').register();

module.exports = {
  assets: require('./src/assets'),
  lambda: require('./src/lambda'),
  model: require('./src/model'),
  logs: require('./src/logs')
};
