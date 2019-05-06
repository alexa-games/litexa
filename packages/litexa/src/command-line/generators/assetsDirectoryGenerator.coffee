
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


fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
Generator = require('./generator')

class AssetsDirectoryGenerator extends Generator
  @description: 'assets directory'

  constructor: (args) ->
    super(args)

  # Public Interface
  generate: ->
    folder = path.join @_rootPath(), 'litexa', 'assets'
    if fs.existsSync folder
      @logger.log 'existing litexa/assets directory found -> skipping creation'
      return Promise.resolve()

    @logger.log 'creating litexa/assets -> place any image/sound asset files that should be
      deployed here'
    mkdirp.sync folder
    Promise.resolve()

module.exports = AssetsDirectoryGenerator
