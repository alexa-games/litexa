###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
Generator = require('./generator')

class SourceCodeGenerator extends Generator
  @description: 'litexa entry point'


  constructor: (args) ->
    super(args)
    @bundlingStrategy = @options.bundlingStrategy
    @projectInfoClass = args.projectInfoClass
    @templateFilesHandlerClass = args.templateFilesHandlerClass
    @directoryCreatorClass = args.directoryCreatorClass

  # Public Interface
  generate: ->
    # Create the Directory Structure
    directoryStructureCreator = new @directoryCreatorClass({
      bundlingStrategy: @bundlingStrategy
      logger: @logger
      rootPath: @_rootPath()
      templateFilesHandlerClass: @templateFilesHandlerClass
      sourceLanguage: @_language()
      projectName: @options.projectConfig.name
    })
    directoryStructureCreator.create()

    # Sync the Project Files
    unless @_hasLitexaCode()
      @logger.log "no code files found in litexa -> creating them"
      directoryStructureCreator.sync()
    else
      @logger.log "existing code files found in litexa -> skipping creation"

    Promise.resolve()

  _hasLitexaCode: ->
    return @foundLitexaCode if @foundLitexaCode?

    projectInfo = new @projectInfoClass @_projectConfig()
    for languageName, language of projectInfo.languages
      for file in language.code.files
        if file.indexOf('.litexa') > 0
          @foundLitexaCode = true
          break

    @foundLitexaCode

  _projectConfig: ->
    @options.projectConfig

  _language: ->
    return @language if @language?
    @language = @options.sourceLanguage

module.exports = SourceCodeGenerator
