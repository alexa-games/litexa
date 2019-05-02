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
