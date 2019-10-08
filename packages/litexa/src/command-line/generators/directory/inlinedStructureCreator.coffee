###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

StructureCreator = require('./structureCreator')

###
# Directory Structure
#
# /litexa   -- Contains all Generated files
#
# Sample Generated Output (-c json -b none -s javascript)
.
├── artifacts.json
├── aws-config.json
├── litexa
│   ├── assets
│   │   ├── icon-108.png
│   │   └── icon-512.png
│   ├── main.litexa
│   ├── main.test.litexa
│   ├── utils.js
│   └── utils.test.js
├── litexa.config.json
└── skill.json
#
###

class InlinedStructureCreator extends StructureCreator
  commonDir = 'common'

  create: ->
    @ensureDirExists @litexaDirectory

  sync: ->
    litexaSource = @path.join commonDir, 'litexa'
    commonLanguageSource = @path.join commonDir, @sourceLanguage
    strategyLanguageSource = @path.join @strategy(), @sourceLanguage

    dirs = [
      litexaSource
      commonLanguageSource
      strategyLanguageSource
    ]

    # litexa directory files
    @templateFilesHandler.syncDir({
      sourcePaths: dirs
      destination: @litexaDirectory,
      dataTransform: @dataTransform.bind(this)
      whitelist: [
        'main.*litexa'
        'util.*(js|coffee|ts)'
        '.*\\.json'
        '.*\\.opts'
      ]
    })

    # root directory files
    @templateFilesHandler.syncDir({
      sourcePaths: dirs
      destination: @rootPath,
      dataTransform: @dataTransform.bind(this)
      whitelist: [
        '.*\\.md$'
        '\\.gitignore$'
      ]
    })

module.exports = InlinedStructureCreator
