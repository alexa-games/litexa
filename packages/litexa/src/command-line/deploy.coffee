chalk = require 'chalk'
debug = require('debug')('litexa')
fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'

LoggingChannel = require './logging-channel'
{ formatLocationStart } = require("../parser/errors.coffee").lib


module.exports.run = (options) ->

  logger = options.logger ? console

  try
    deploymentStartTime = new Date

    # ok, load skill
    skill = await require('./skill-builder').build(options.root)
    options.deployment = options.deployment ? 'development'
    skill.projectInfo.variant = options.deployment

    # deployment artifacts live in this temp directory
    deployRoot = path.join skill.projectInfo.root, '.deploy', skill.projectInfo.variant
    mkdirp.sync deployRoot

    output = options.logger ? console
    logger = new LoggingChannel 'deploy', output, path.join(deployRoot,'deploy.log'), options.verbose

    # couldn't log this until now, but it's close enough
    logger.log "skill build complete in #{(new Date) - deploymentStartTime}ms"

    logger.important "beginning deployment of #{skill.projectInfo.root}"

    # deploy what?
    deploymentTypes = parseDeploymentTypes(options)

    unless 'deployments' of skill.projectInfo
      throw "missing `deployments` key in the litexa config file, can't continue without parameters
        to pass to the deployment module!"

    deploymentOptions = skill.projectInfo.deployments[options.deployment]

    unless deploymentOptions?
      throw "couldn't find a deployment called `#{options.deployment}` in the deployments section
        of the litexa config file, cannot continue."

    deployModule = require('../deployment/deployment-module')(skill.projectInfo.root, deploymentOptions, logger)
    deployModule.manifest = require('./deploy/manifest')


    # the context gets passed between the steps, to
    # collect shared information
    context =
      skill: skill
      projectInfo: skill.projectInfo
      projectConfig: skill.projectInfo
      deployRoot: deployRoot
      projectRoot: skill.projectInfo?.root
      sharedDeployRoot: path.join skill.projectInfo.root, '.deploy'
      cache: options.cache
      deploymentName: options.deployment
      deploymentOptions: skill.projectInfo.deployments[options.deployment]
      JSONValidator: require('../parser/jsonValidator').lib.JSONValidator

  catch err
    logger.error err
    return

  require('../deployment/artifacts.coffee').loadArtifacts context, logger
  .then ->
    require('../deployment/git.coffee').getCurrentState()
    .then (info) ->
      context.artifacts.save "lastDeployment", {
        date: (new Date).toLocaleString()
        deploymentTypes: deploymentTypes
        git: info
      }
      Promise.resolve()
  .then ->
    # neither of these rely on the other, let them interleave
    step1 = []
    if deploymentTypes.assets
      assetsLogger = new LoggingChannel 'assets', output, path.join(deployRoot,'assets.log'), options.verbose
      assetsPipeline = Promise.resolve()
      .then ->
        # run all the external converters
        require('../deployment/assets').convertAssets context, assetsLogger
      .then ->
        deployModule.assets.deploy context, assetsLogger
      step1.push assetsPipeline

    if deploymentTypes.lambda
      lambdaLogger = new LoggingChannel 'lambda', output, path.join(deployRoot,'lambda.log'), options.verbose
      step1.push deployModule.lambda.deploy context, lambdaLogger

    Promise.all step1
  .then ->
    # manifest depends on the lambda deployment
    if deploymentTypes.manifest
      lambdaLogger = new LoggingChannel 'manifest', output,   path.join(deployRoot,'manifest.log'), options.verbose
      deployModule.manifest.deploy context, lambdaLogger
    else
      Promise.resolve()
  .then ->
    # model upload must be after the manifest, as the skill must exist
    if deploymentTypes.model
      deployModule.model.deploy skill
    else
      Promise.resolve()
  .then ->
    deltaTime = (new Date) - deploymentStartTime
    logger.important "deployment complete in #{deltaTime}ms"
  .catch (err) ->
    if err.location and err.message
      location = formatLocationStart(err.location)
      name = if err.name then err.name else "Error"
      message = err.message

      line = "#{location}: #{name}: #{message}"
      logger.error line
    else
      logger.error err

    deltaTime = (new Date) - deploymentStartTime
    logger.important "deployment FAILED in #{deltaTime}ms"


parseDeploymentTypes = (options) ->
  optionTypes = ( d.trim() for d in options.type.split ',' )

  deploymentTypes =
    lambda: false
    assets: false
    model: false
    manifest: false

  for type in optionTypes
    unless type of deploymentTypes or type == 'all'
      throw new Error "Unrecognized deployment type `#{type}`"

  deployAll = 'all' in optionTypes

  for key of deploymentTypes
    deploymentTypes[key] = (key in optionTypes) or deployAll

  return deploymentTypes