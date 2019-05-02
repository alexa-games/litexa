chalk = require 'chalk'
path = require 'path'
fs = require 'fs'
mkdirp = require 'mkdirp'
debug = require('debug')('litexa')

LoggingChannel = require './logging-channel'

module.exports.run = (options, after) ->
  logger = new LoggingChannel 'logs'

  logger.important "Beginning log pull"

  config = require './project-config'
  options.projectConfig = await config.loadConfig options.root
  options.projectInfo = new (require './project-info')(options.projectConfig, options.deployment)

  options.logsRoot = path.join options.projectConfig.root, '.logs'
  mkdirp.sync options.logsRoot

  logger.log "logs root at #{options.logsRoot}"

  unless 'deployments' of options.projectInfo
    throw new Error "missing `deployments` key in the litexa config file, can't continue without
      parameters to pass to the deployment module!"

  options.deployment = options.deployment ? 'development'
  deploymentOptions = options.projectInfo.deployments[options.deployment]
  options.deploymentName = options.deployment
  options.projectRoot = options.projectConfig.root
  options.deploymentOptions = deploymentOptions
  unless deploymentOptions?
    throw new Error "couldn't find a deployment called `#{options.deployment}` in the deployments
      section of the litexa config file, cannot continue."

  deployModule = require('../deployment/deployment-module')(options.projectConfig.root, deploymentOptions, logger)
  deployModule.logs.pull options, logger
  .then ->
    logger.important "done pulling logs"
  .catch (error) ->
    logger.important error
