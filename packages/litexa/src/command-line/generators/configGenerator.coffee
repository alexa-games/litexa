require('@src/getter.polyfill')
debug = require('debug')('config-generator')
path = require 'path'
Generator = require('./generator')
strategies = require('../bundlingStrategies')
projectNameValidate = require('./validators/projectNameValidator')

class ConfigGenerator extends Generator
  @description: 'config file'

  constructor: (args) ->
    super(args)
    @bundlingStrategy = @options.bundlingStrategy
    @config = args.config
    @inquirer = args.inputHandler
    @templateFilesHandlerClass = args.templateFilesHandlerClass

  # Public Methods
  generate: ->
    configFileName = await @_configFile()

    configRoot =
      if configFileName?
        path.dirname configFileName
      else
        options = {
          type: 'input'
          name: 'projectName'
          message: @_inputQuestion()
          validate: projectNameValidate
        }
        options.default = @defaultName if @defaultName?

        result = await @inquirer.prompt(options)
        @_writeFiles(result.projectName)

        @_rootPath()

    unless configRoot == @_rootPath()
      throw new Error "Config file found in ancestor directory #{configRoot}"

    # Direct Public Side-Effect
    @options.projectConfig = await @config.loadConfig configRoot

    Promise.resolve()

  # "Private" Methods
  _inputQuestion: () ->
    question =  "What would you like to name the project?"
    if @defaultName?
      question = "#{question} (default: \"#{@defaultName}\")"
    question

  _writeFiles: (name) ->
    configFilename = @config.writeDefault @_rootPath(), @_configLanguage(), name
    @logger.log "creating #{configFilename} -> contains deployment settings and should be version
      controlled"

  _configFile: ->
    try
      fileName = await @config.identifyConfigFileFromPath @_rootPath()
      @logger.log "existing #{fileName} found -> skipping creation"

      fileName
    catch err
      debug err

      undefined

  _configLanguage: ->
    @options.configLanguage

  # Getters / Setters
  @getter 'defaultName', ->
    return @nameCandidate if @nameCandidate
    nameCandidate = path.basename @_rootPath()
    try
      @nameCandidate = nameCandidate if projectNameValidate(nameCandidate)
    @nameCandidate

module.exports = ConfigGenerator
