###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

require '@src/getter.polyfill'
path = require 'path'
StructureCreator = require('./structureCreator')

###
# Directory Structure
#
# /litexa -- Contains litexa specific files and package.json link to business logic
# /lib    -- Contains all generated business logic files
#
# Sample Generated Output (-c coffee -s coffee -b npm-link)
#
.
├── artifacts.json
├── aws-config.json
├── lib
│   ├── index.coffee
│   ├── logger.coffee
│   ├── mocha.opts
│   ├── package.json
│   ├── utils.coffee
│   └── utils.spec.coffee
├── litexa
│   ├── assets
│   │   ├── icon-108.png
│   │   └── icon-512.png
│   ├── main.coffee
│   ├── main.litexa
│   ├── main.test.litexa
│   └── package.json
├── litexa.config.coffee
└── skill.coffee
#
###

class SeparateStructureCreator extends StructureCreator
  separateFolder = 'lib'
  commonDir = 'common'

  create: ->
    @ensureDirExists @litexaDirectory
    @ensureDirExists @separateFolder

  sync: ->
    prefix = @strategy()

    litexaSource = @path.join commonDir, 'litexa'
    litexaLanguageHook = @path.join prefix, 'litexa'
    commonLanguageSource = @path.join commonDir, @sourceLanguage

    if @sourceLanguage == 'typescript'
      commonLanguageSource = @path.join commonLanguageSource, 'source'

    strategyLanguageSource = @path.join prefix, @sourceLanguage

    whitelist = [
      'main.*litexa'
      'util.*(js|coffee|ts)'
      'logger.*(js|coffee|ts)'
      'index.*(js|coffee|ts)'
      '.*\\.json'
      '.*\\.opts'
      '\\.es.*'
      '.*rc$'
    ]

    if @sourceLanguage == 'coffee'
      whitelist.push('main.coffee$')
    else
      whitelist.push('main.js$')

    if @sourceLanguage == 'typescript'
      whitelist.push '.*\\.d.ts$'

    # litexa directory files
    @templateFilesHandler.syncDir({
      sourcePaths: [
        litexaSource
        litexaLanguageHook
      ]
      destination: @litexaDirectory
      dataTransform: @dataTransform.bind(this)
      whitelist
    })

    # lib directory files
    @templateFilesHandler.syncDir({
      sourcePaths: [
        commonLanguageSource
        strategyLanguageSource
      ]
      destination: @separateFolder
      dataTransform: @dataTransform.bind(this)
      whitelist
    })

    # root directory files
    @templateFilesHandler.syncDir({
      sourcePaths: [
        litexaSource
        litexaLanguageHook
        commonLanguageSource
        strategyLanguageSource
      ]
      destination: @rootPath,
      dataTransform: @dataTransform.bind(this)
      whitelist: [
        '.*\\.md$'
        '\\.gitignore$'
      ]
    })

  # Getters and Setters

  @getter 'separateFolder', ->
    return @separateDir if @separateDir
    @separateDir = path.join @rootPath, separateFolder

module.exports = SeparateStructureCreator
