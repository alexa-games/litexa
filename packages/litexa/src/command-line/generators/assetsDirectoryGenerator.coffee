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
