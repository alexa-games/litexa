
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
    assert(fs.existsSync(path.join context.sharedDeployRoot, 'converted-assets', 'default', 'someFile.wav.mp3'), 'converted asset for default exists')
    assert(fs.existsSync(path.join context.sharedDeployRoot, 'converted-assets', 'de-DE', 'anotherFile.wav.mp3'), 'converted asset for other locales exists')
    assert(logSpy.calledOnceWith(match('conversion complete')), 'conversion process finished')
