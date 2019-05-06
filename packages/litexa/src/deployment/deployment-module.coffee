
###

 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved.
 * These materials are licensed as "Restricted Program Materials" under the Program Materials
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service.
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html.
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized
 * terms not defined in this file have the meanings given to them in the Agreement.
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

###


path = require 'path'
fs = require 'fs'
debug = require('debug')('litexa')


module.exports = (projectRoot, deploymentOptions, logger) ->
  # load deployment extension, assumed to either be local
  # or installed globally wherever npm install -g goes
  unless deploymentOptions.module?
    throw "deployment.module not defined in litexa.config.json"

  deployModule = null
  tryPath = (fn) ->
    return if deployModule?
    prefix = fn()
    fullPath = path.join prefix, deploymentOptions.module
    debug "searching for deployment module in #{fullPath}"
    unless fs.existsSync fullPath
      debug "no deploy module, #{err}"
      return

    try
      deployModule = require fullPath
      logger.log "loaded deployment module from #{fullPath}"
    catch err
      logger.error "failed to load deployment module: #{err}"

  tryPath ->
    path.join projectRoot, "node_modules"

  npmGlobalPath = null
  tryPath ->
    # ask npm where its globals are
    {execSync} = require('child_process')
    npmGlobalPath = execSync("npm config get prefix").toString().trim()
    debug "npm global path is #{npmGlobalPath}"
    unless fs.existsSync npmGlobalPath
      throw "failed to retrieve global modules path with `npm config get prefix`
        Try and run this yourself to debug why."

    path.join npmGlobalPath, 'node_modules'

  tryPath -> path.join npmGlobalPath, 'lib', 'node_modules'

  return deployModule if deployModule?

  throw "Failed to load deployment module #{deploymentOptions.module}, from
    both the local and global locations. Have you npm installed it?"
