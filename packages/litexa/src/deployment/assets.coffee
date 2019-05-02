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
