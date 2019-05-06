
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
