#!/usr/bin/env node

var coffee = require('coffeescript').register();

module.exports = {
  assets: require('./src/assets.coffee'),
  lambda: require('./src/lambda.coffee'),
  model: require('./src/model.coffee'),
  logs: require('./src/logs.coffee')
};
