pino = require 'pino'
prettifier = require 'pino-pretty'

config =
  name: '{name}-skill'
  level: process.env.LOGGER_LEVEL || 'debug'
  prettyPrint:
    levelFirst: true
  prettifier: prettifier

logger = pino config

module.exports = logger
