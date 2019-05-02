require('@src/getter.polyfill')
extensions = require('../fileExtensions')
fs = require 'fs'
manifest = require('../manifest')
path = require 'path'
Generator = require('./generator')
skillStoreTitleValidate = require('./validators/skillStoreTitleValidator')

class SkillManifestGenerator extends Generator
  @description: 'skill manifest'

  constructor: (args) ->
    super(args)
    @inquirer = args.inputHandler

  # public interface
  generate: ->
    extension = extensions[@_configLanguage()]

    unless extension?
      throw new Error "#{@_configLanguage()} language extension not found"

    filename = "skill.#{extension}"
    filePath = path.join @_rootPath(), "skill.#{extension}"

    if fs.existsSync filePath
      @logger.log "existing #{filename} found -> skipping creation"
      return Promise.resolve()

    options = {
      type: 'input'
      name: 'storeTitleName'
      message: @_inputQuestion()
      validate: skillStoreTitleValidate
    }
    options.default = @defaultProjectName if @defaultProjectName?

    result = await @inquirer.prompt(options)
    name = result.storeTitleName

    skillManifest = manifest.create name, @_configLanguage()
    fs.writeFileSync filePath, skillManifest, 'utf8'
    @logger.log "creating #{filename} -> contains skill manifest and should be version
      controlled"

    Promise.resolve()

  # "private" methods
  _inputQuestion: ->
    question =  'What would you like the skill store title of the project to be?'
    if @defaultProjectName?
      question = "#{question} (default: \"#{@defaultProjectName}\")"
    question

  _configLanguage: ->
    @options.configLanguage

  # Getters / Setters
  @getter 'defaultProjectName', ->
    return @nameCandidate if @nameCandidate
    nameCandidate = @options.projectConfig?.name
    try
      @nameCandidate = nameCandidate if skillStoreTitleValidate(nameCandidate)
    @nameCandidate


module.exports = SkillManifestGenerator
