###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

inquirer = require 'inquirer'
{ Artifacts } = require('../deployment/artifacts')

ArtifactTrackerGenerator = require('./generators/artifactTrackerGenerator')
AssetsDirectoryGenerator = require('./generators/assetsDirectoryGenerator')
ConfigGenerator = require('./generators/configGenerator')
DirectoryCreator = require('./generators/directoryCreator')
DirectoryStructureCreator = require('./generators/directory/structureCreator')
LoggingChannel = require './loggingChannel'
ProjectInfo = require('./project-info')
SkillIconsGenerator = require('./generators/skillIconsGenerator')
SkillManifestGenerator = require('./generators/skillManifestGenerator')
SourceCodeGenerator = require('./generators/sourceCodeGenerator')
TemplateFilesHandler = require('./generators/templateFilesHandler')

config = require './project-config'

module.exports.run = (options) ->
  logger = new LoggingChannel({
      logStream: options.logger ? console
      logPrefix: 'generator'
      verbose: options.verbose
    })
  # absent any other options, generate all assets that don't exist
  logger.important "Beginning project generators"

  dirCreator = new DirectoryStructureCreator({logger})
  dirCreator.ensureDirExists options.dir

  steps = [
    ConfigGenerator,
    ArtifactTrackerGenerator,
    SkillManifestGenerator,
    SourceCodeGenerator,
    AssetsDirectoryGenerator,
    SkillIconsGenerator
  ]

  promise = Promise.resolve()

  for generator in steps
    do (generator) ->
      subLogger = logger.derive generator.description
      promise = promise.then ->
        promise = new generator({
          # Common Options
          options,
          logger: subLogger,
          # Generator-Specific Injected Dependencies
          inputHandler: inquirer,                           # ConfigGenerator, SkillManifestGenerator
          config,                                           # ConfigGenerator
          artifactClass: Artifacts,                         # ArtifactTrackerGenerator
          projectInfoClass: ProjectInfo,                    # SourceCodeGenerator
          templateFilesHandlerClass: TemplateFilesHandler,  # ConfigGenerator, SourceCodeGenerator
          directoryCreatorClass: DirectoryCreator           # SourceCodeGenerator
        }).generate()
      .then ->
        subLogger.log 'complete'

  promise.then ->
    logger.important 'Completed generation -> please consult the README.md for next steps.'
  .catch (err) ->
    logger.error err
    logger.important "Generation failed"
