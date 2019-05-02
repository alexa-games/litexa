require '@src/getter.polyfill'
fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
searchReplace = require '../searchReplace'
strategies = require('../../bundlingStrategies')

class StructureCreator
  constructor: (args) ->
    @logger = args.logger
    @rootPath = args.rootPath
    @sourceLanguage = args.sourceLanguage
    @templateFilesHandler = args.templateFilesHandler
    @bundlingStrategy = args.bundlingStrategy
    @projectName = args.projectName
    @fs = args.syncFileHandler || fs
    @mkdirp = args.syncDirWriter || mkdirp
    @path = args.path || path

  ensureDirExists: (directory) ->
    unless @fs.existsSync directory
      @logger.log "no #{directory} directory found -> creating it"
      @mkdirp.sync directory

  strategy: ->
    strategies[@bundlingStrategy]

  create: ->
    throw new Error "#{this.constructor.name}#create not implemented"

  sync: ->
    throw new Error "#{this.constructor.name}#sync not implemented"

  dataTransform: (dataString) ->
    searchReplace dataString, {name: @projectName}

  # Getters and Setters
  @getter 'litexaDirectory', ->
    return @litexaFolder if @litexaFolder
    @litexaFolder = @path.join @rootPath, 'litexa'

module.exports = StructureCreator
