###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

Assets = require('@src/deployment/assets')
rimraf = require 'rimraf'
fs = require 'fs'
path = require 'path'
util = require 'util'

chai = require('chai')
chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
{assert, expect} = chai
{match, spy} = require('sinon')

describe 'converts assets', ->
  loggerInterface = undefined
  context = undefined

  beforeEach ->
    assetProcessor = (input) ->
      new Promise (resolve, reject) ->
        fs.writeFileSync(path.join(input.targetsRoot, input.assetName + '.mp3'), '', 'utf8')
        resolve()


    loggerInterface = {
      log: -> undefined
    }
    context =
      projectInfo:
        languages:
          'default':
            assetProcessors:
              'wav to mp3 converter':
                process: assetProcessor
                inputs: [ 'someFile.wav' ]
            assets:
              root: './litexa/assets'
          'de-DE':
            assetProcessors:
              'wav to mp3 converter':
                process: assetProcessor
                inputs: [ 'anotherFile.wav' ]
                options: {}
            assets:
              root: './litexa/de-DE/assets'
          'fr-FR':
            assetProcessors:
              'wav to mp3 converter':
                process: assetProcessor
                inputs: []
                options: {}
            assets:
              root: './litexa/de-DE/assets'
      sharedDeployRoot: '.deploy'

  afterEach ->
    rimraf.sync '.deploy'

  it 'converts assets and puts them in the converted assets directory', ->
    logSpy = spy(loggerInterface, 'log')
    await Assets.convertAssets(context, loggerInterface)
    assert(fs.existsSync(path.join context.sharedDeployRoot, 'converted-assets'), 'converted-assets directory exists')
    assert(fs.existsSync(path.join context.sharedDeployRoot, 'converted-assets', 'default', 'someFile.wav.mp3'), 'converted default asset exists')
    assert(fs.existsSync(path.join context.sharedDeployRoot, 'converted-assets', 'de-DE', 'anotherFile.wav.mp3'), 'converted localized-only asset exists')
    assert(fs.existsSync(path.join context.sharedDeployRoot, 'converted-assets', 'de-DE', 'someFile.wav.mp3'), 'converted default-only asset exists in a locale with other converted assets')
    assert(fs.existsSync(path.join context.sharedDeployRoot, 'converted-assets', 'fr-FR', 'someFile.wav.mp3'), 'converted default-only asset exists in a locale with no other converted assets')
    assert(logSpy.calledOnceWith(match('conversion complete')), 'conversion process finished')
