#!/usr/bin/env node
require('../../aliasing');
var coffee = require('coffeescript').register();
require('./router.coffee').run();
