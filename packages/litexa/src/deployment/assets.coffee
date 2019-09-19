
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
  debug "assets conversion cache at #{cacheRoot}"

  for languageName, languageInfo of context.projectInfo.languages
    languageCacheDir = path.join cacheRoot, languageName
    mkdirp.sync languageCacheDir

    # Add promises to run all of our asset processors.
    for kind, processor of languageInfo.assetProcessors
      for input in processor.inputs
        promises.push(processor.process({
          assetName: input
          assetsRoot: languageInfo.assets.root
          targetsRoot: languageCacheDir
          options: processor.options
          logger: logger
        }))

  Promise.all promises
  .then ->
    logger.log "all asset conversion complete"

    # Now, let's check if there were any "default" converted files that aren't available in a
    # localized language. If so, copy these common assets to the language for deployment.
    defaultCacheDir = path.join cacheRoot, 'default'
    for languageName of context.projectInfo.languages
      if languageName != 'default'
        languageCacheDir = path.join cacheRoot, languageName
        defaultFiles = fs.readdirSync(defaultCacheDir)

        for fileName in defaultFiles
          dst = path.join languageCacheDir, fileName
          # If a default file isn't being overridden by this language, copy it to language.
          unless fs.existsSync(dst)
            src = path.join defaultCacheDir, fileName
            fs.copyFileSync(src, dst)
