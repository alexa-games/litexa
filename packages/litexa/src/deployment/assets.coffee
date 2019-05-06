
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
mkdirp = require 'mkdirp'
debug = require('debug')('litexa-assets')


exports.convertAssets = (context, logger) ->
  promises = []

  cacheRoot = path.join context.sharedDeployRoot, 'converted-assets'
  mkdirp.sync cacheRoot
  debug "assets conversion cache at #{cacheRoot}"

  for languageName, languageInfo of context.projectInfo.languages
    for kind, proc of languageInfo.assetProcessors
      for input in proc.inputs
        promises.push proc.process
          assetName: input
          assetsRoot: languageInfo.assets.root
          targetsRoot: cacheRoot
          options: proc.options
          logger: logger


  Promise.all promises
  .then ->
    logger.log "all asset conversion complete"
