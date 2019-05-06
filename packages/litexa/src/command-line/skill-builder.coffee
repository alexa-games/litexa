
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


{ Skill } = require '../parser/skill.coffee'
fs = require 'fs'
path = require 'path'
debug = require('debug')('litexa')

config = require './project-config'

build = (root) ->
  require('../parser/parserlib.coffee').__resetLib()

  jsonConfig = await config.loadConfig root
  projectInfo = new (require './project-info')(jsonConfig)

  skill = new Skill projectInfo
  skill.strictMode = true

  for language, languageInfo of projectInfo.languages
    codeInfo = languageInfo.code
    for file in codeInfo.files
      filename = path.join codeInfo.root, file
      data = fs.readFileSync filename, 'utf8'
      skill.setFile file, language, data

  return skill

module.exports =
  build: build
