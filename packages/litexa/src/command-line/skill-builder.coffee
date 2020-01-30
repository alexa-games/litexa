###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

{ Skill } = require '../parser/skill.coffee'
fs = require 'fs'
path = require 'path'
debug = require('debug')('litexa')

config = require './project-config'

build = (root, variant) ->
  require('../parser/parserlib.coffee').__resetLib()

  jsonConfig = await config.loadConfig root
  projectInfo = new (require './project-info')({jsonConfig, variant})

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
