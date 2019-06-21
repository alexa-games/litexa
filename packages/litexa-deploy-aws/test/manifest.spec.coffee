
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


fs = require 'fs'
path = require 'path'
rimraf = require 'rimraf'
mkdirp = require 'mkdirp'
Manifest = require('@litexa/core/src/command-line/deploy/manifest')
{defaultManifest} = require('./helpers')

chai = require('chai')
chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
{assert, expect} = chai
{match, spy, stub, mock} = require('sinon')


describe 'construct and deploy artifacts for manifest', ->
  loggerInterface = undefined
  context = undefined
  sampleArtifacts = undefined
  errorThrown = undefined

  beforeEach ->
    loggerInterface = {
      log: -> undefined
      error: -> undefined
      warning: -> undefined
      verbose: -> undefined
      derive: -> undefined
    }
    context =
      # manifest uses require() and it doesn't work in test execution with relative paths
      projectRoot: path.join(process.cwd(), '.manifest-test')
      artifacts:
        get: -> undefined
        save: -> undefined
      deploymentName: "test"
      deploymentOptions:
        askProfile: "askProfile"
        invocation:
          "en-US": "alternate name"
        invocationSuffix: "suffix"
      deployRoot: ".manifest-test/.deploy/test"
      projectInfo:
        variant: "test"
        extensions:
          testExtension:
            manifestValidator: -> undefined
            modelValidator: -> undefined
        name: "project name"
      skill:
        collectRequiredAPIs: -> undefined
        toModelV2: -> undefined
    sampleArtifacts =
      lambdaARN: "dummyLambdaARN"
      'required-assets':
        'icon-108.png':
          'url': 'dummyUrl'
        'icon-512.png':
          'url': 'dummyUrl'
    errorThrown = false
    mkdirp.sync '.manifest-test'
    mkdirp.sync context.deployRoot

  afterEach ->
    delete require.cache[require.resolve(path.join context.projectRoot, 'skill.coffee')]
    fs.unlinkSync "./.manifest-test/skill.coffee"
    rimraf.sync '.manifest-test'

  validArtifacts = (name) ->
    return sampleArtifacts[name]

  it 'does not find a skill file and generates a default', ->
    deployManifest = -> Manifest.deploy context, loggerInterface
    try
      await Manifest.deploy context, loggerInterface
    catch e
      errorThrown = true
      assert(e?, 'exception was thrown')
      assert.include(e, "skill.* was not found in project root", 'missing skill.* thrown')
    assert(errorThrown, 'an exception was thrown')
    assert(fs.existsSync(path.join context.projectRoot, 'skill.coffee'), 'it generated a default skill.coffee')
    generatedManifest = require '../.manifest-test/skill'
    assert.equal generatedManifest.manifest.publishingInformation.locales['en-US'].name, "Project Name"

  it 'loads an invalid skill file - missing `manifest`', ->
    logSpy = spy(loggerInterface, 'log')
    errorSpy = spy(loggerInterface, 'error')
    fs.writeFileSync "./.manifest-test/skill.coffee", 'module.exports = {foo:"bar"}', 'utf8'
    dummy = -> undefined
    try
      await Manifest.deploy context, loggerInterface
    catch e
      errorThrown = true
      assert(e?, 'exception was thrown')
      assert.equal(e, "failed manifest deployment")
    assert(errorThrown, 'an exception was thrown')
    assert(logSpy.calledWith(match("building skill manifest")), 'it loaded skill info')
    assert(errorSpy.calledWith(match("Didn't find a 'manifest' property")),
      'manifest file missing `manifest` field')

  it 'loads an invalid skill file - missing `lambdaARN`', ->
    logSpy = spy(loggerInterface, 'log')
    errorSpy = spy(loggerInterface, 'error')
    fs.writeFileSync "./.manifest-test/skill.coffee", 'module.exports = {manifest:"bar"}', 'utf8'

    try
      await Manifest.deploy context, loggerInterface
    catch e
      errorThrown = true
      assert(e?, 'exception was thrown')
      assert.equal(e, "failed manifest deployment")
    assert(errorThrown, 'an exception was thrown')
    assert(logSpy.calledWith(match("building skill manifest")), 'it loaded skill info')
    assert(errorSpy.calledWith(match("Missing lambda ARN")), 'artifacts file missing `lambdaARN` field')

  it 'writes a skill.json, uses variant in name and alternate invocation from deployment options', ->
    context.artifacts.get = validArtifacts
    delete context.deploymentOptions.invocationSuffix
    delete context.deploymentOptions.askProfile
    errorSpy = spy(loggerInterface, 'error')

    fs.writeFileSync "./.manifest-test/skill.coffee", defaultManifest, 'utf8'
    try
      await Manifest.deploy context, loggerInterface
    catch
      errorThrown = true
      assert(errorSpy.calledWith(match("missing an ASK profile")), 'execution stopped at calling SMAPI')
    assert(errorThrown, 'an exception was thrown')
    assert(fs.existsSync path.join(context.deployRoot,'skill.json'), 'manifest file was written')
    writtenManifest = JSON.parse fs.readFileSync path.join(context.deployRoot,'skill.json')
    assert(writtenManifest.manifest.publishingInformation.locales.hasOwnProperty('en-US'), 'there is a en-US locale')
    assert(writtenManifest.manifest.publishingInformation.locales.hasOwnProperty('en-GB'), 'there is a en-GB locale')
    expect(writtenManifest.manifest.publishingInformation.locales['en-US'].name).to.include('(test)')
    expect(writtenManifest.manifest.publishingInformation.locales['en-GB'].name).to.include('(test)')
    expect(writtenManifest.manifest.publishingInformation.locales['en-US'].examplePhrases[0]).to.include('alternate name')
    expect(writtenManifest.manifest.publishingInformation.locales['en-GB'].examplePhrases[0]).to.not.include('alternate name')

  it 'applies suffix from deploymentOptions regardless of alternate invocation', ->
    context.artifacts.get = validArtifacts
    delete context.deploymentOptions.askProfile
    errorSpy = spy(loggerInterface, 'error')

    fs.writeFileSync "./.manifest-test/skill.coffee", defaultManifest, 'utf8'
    try
      await Manifest.deploy context, loggerInterface
    catch
      errorThrown = true
      assert(errorSpy.calledWith(match("missing an ASK profile")), 'execution stopped at calling SMAPI')
    assert(errorThrown, 'an exception was thrown')
    assert(fs.existsSync path.join(context.deployRoot,'skill.json'), 'manifest file was written')
    writtenManifest = JSON.parse fs.readFileSync path.join(context.deployRoot,'skill.json')
    expect(writtenManifest.manifest.publishingInformation.locales['en-US'].examplePhrases[0]).to.include('alternate name suffix')
    expect(writtenManifest.manifest.publishingInformation.locales['en-GB'].examplePhrases[0]).to.not.include('alternate name')
    expect(writtenManifest.manifest.publishingInformation.locales['en-GB'].examplePhrases[0]).to.include('suffix')

  it 'does not apply `(variant)` to skill name if deployment target is `production`', ->
    context.artifacts.get = validArtifacts
    delete context.deploymentOptions.askProfile
    context.projectInfo.variant = 'production'
    errorSpy = spy(loggerInterface, 'error')

    fs.writeFileSync "./.manifest-test/skill.coffee", defaultManifest, 'utf8'
    try
      await Manifest.deploy context, loggerInterface
    catch
      errorThrown = true
      assert(errorSpy.calledWith(match("missing an ASK profile")), 'execution stopped at calling SMAPI')
    assert(errorThrown, 'an exception was thrown')
    assert(fs.existsSync path.join(context.deployRoot,'skill.json'), 'manifest file was written')
    writtenManifest = JSON.parse fs.readFileSync path.join(context.deployRoot,'skill.json')
    expect(writtenManifest.manifest.publishingInformation.locales['en-GB'].examplePhrases[0]).to.not.include('(')
    expect(writtenManifest.manifest.publishingInformation.locales['en-GB'].examplePhrases[0]).to.not.include('(')
