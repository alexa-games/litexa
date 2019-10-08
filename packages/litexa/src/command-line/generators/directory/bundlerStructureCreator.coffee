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
# /litexa       -- Contains litexa specific files
# /lib          -- Root folder for application being developed
#   /services   -- Location for service layer calls / data access calls
#   /components -- Location for misc business logic ordered by components
# /test         -- Test root folder for the application being developer
#   /services   -- Location for service layer calls / data access calls tests
#   /components -- Location for misc business logic ordered by components tests
#
# Sample Generated Output (-c typescript -s typescript -b webpack)
#
├── lib
│   ├── components
│   │   ├── logger.ts
│   │   └── utils.ts
│   ├── index.ts
│   ├── pino-pretty.d.ts
│   └── services
│       └── time.service.ts
├── artifacts.json
├── aws-config.json
├── globals.d.ts
├── litexa
│   ├── assets
│   │   ├── icon-108.png
│   │   └── icon-512.png
│   ├── main.litexa
│   └── main.test.litexa
├── mocha.opts
├── package.json
├── litexa.config.js
├── litexa.config.ts
├── skill.ts
├── test
│   ├── components
│   │   └── utils.spec.ts
│   └── services
│       └── time.service.spec.ts
├── tsconfig.json
├── tslint.json
└── webpack.config.js
#
###

class BundlerStructureCreator extends StructureCreator
  libDir = 'lib'
  testDir = 'test'
  commonDir = 'common'

  create: ->
    @ensureDirExists @litexaDirectory

    @ensureDirExists @libServicesDirectory
    @ensureDirExists @libComponentsDirectory

    @ensureDirExists @testServicesDirectory
    @ensureDirExists @testComponentsDirectory

  sync: ->
    prefix = @strategy()

    litexaSource = @path.join commonDir, 'litexa'
    commonLanguageSource = @path.join commonDir, @sourceLanguage
    commonLanguageSource = @path.join commonLanguageSource, 'source' if @sourceLanguage == 'typescript'
    strategyLanguageSource = @path.join prefix, @sourceLanguage
    strategyLanguageSource = @path.join strategyLanguageSource, 'source' if @sourceLanguage == 'typescript'

    languageDirs = [
      commonLanguageSource
      strategyLanguageSource
    ]

    # Populate litexa folder
    @templateFilesHandler.syncDir({
      sourcePaths: [
        litexaSource
      ]
      destination: @litexaDirectory
      whitelist: [
        'main.*litexa'
      ]
    })

    # Populate top-level lib directory
    libDirWhitelist = [
      'index.(js|coffee|ts)$'
    ]
    if @sourceLanguage == 'typescript'
      libDirWhitelist.push '.*\\.d.ts$'

    @templateFilesHandler.syncDir({
      sourcePaths: languageDirs
      destination: @libDirectory
      dataTransform: @dataTransform.bind(this)
      whitelist: libDirWhitelist
    })

    # Populate lib services
    @templateFilesHandler.syncDir({
      sourcePaths: languageDirs
      destination: @libServicesDirectory
      dataTransform: @dataTransform.bind(this)
      whitelist: [
        '.*\\.service\\.(js|coffee|ts)$'
      ]
    })

    # Populate lib components
    @templateFilesHandler.syncDir({
      sourcePaths: languageDirs
      destination: @libComponentsDirectory
      dataTransform: @dataTransform.bind(this)
      whitelist: [
        'utils\\.(js|coffee|ts)$'
        'logger\\.(js|coffee|ts)$'
      ]
    })

    # Populate lib services tests
    @templateFilesHandler.syncDir({
      sourcePaths: languageDirs
      destination: @testServicesDirectory
      dataTransform: @dataTransform.bind(this)
      whitelist: [
        '.*\\.service\\.spec\\.(js|coffee|ts)$'
      ]
    })

    # Populate lib components tests
    @templateFilesHandler.syncDir({
      sourcePaths: languageDirs
      destination: @testComponentsDirectory
      dataTransform: @dataTransform.bind(this)
      whitelist: [
        'utils.spec.(js|coffee|ts)$'
      ]
    })

    # Populate and override top-level files and configurations
    if @sourceLanguage == 'typescript'

      languageDirs.unshift(@path.join prefix, @sourceLanguage, 'config')
      languageDirs.unshift(@path.join commonDir, @sourceLanguage, 'config')

    @templateFilesHandler.syncDir({
      sourcePaths: [litexaSource].concat languageDirs
      destination: @rootPath
      dataTransform: @dataTransform.bind(this)
      whitelist: [
        '\\.gitignore$'
        '.*\\.md$'
        '.*\\.json$'
        '.*\\.opts$'
        '.*rc$'
        'webpack.config.js'
      ]
    })

  # Getters and Setters

  @getter 'libDirectory', ->
    return @libFolder if @libFolder
    @libFolder = path.join @rootPath, libDir

  @getter 'testDirectory', ->
    return @testFolder if @testFolder
    @testFolder = path.join @rootPath, testDir

  @getter 'libServicesDirectory', ->
    return @libServicesFolder if @libServicesFolder
    @libServicesFolder = path.join @libDirectory, 'services'

  @getter 'libComponentsDirectory', ->
    return @libComponentsFolder if @libComponentsFolder
    @libComponentsFolder = path.join @libDirectory, 'components'

  @getter 'testServicesDirectory', ->
    return @testServicesFolder if @testServicesFolder
    @testServicesFolder = path.join @testDirectory, 'services'

  @getter 'testComponentsDirectory', ->
    return @testComponentsFolder if @testComponentsFolder
    @testComponentsFolder = path.join @testDirectory, 'components'

module.exports = BundlerStructureCreator
