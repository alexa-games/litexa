
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


{assert, expect} = require('chai')
{match, spy, stub} = require('sinon')
{lambdaTriggerStatement} = require('./helpers')
{unitTestHelper} = require('../src/lambda')

fs = require 'fs'
path = require 'path'
rimraf = require 'rimraf'
mkdirp = require 'mkdirp'

describe 'Running Deploy to Lambda', ->
  loggerInterface = undefined
  context = undefined
  lambdaContext = undefined

  beforeEach ->
    loggerInterface = {
      log: -> undefined
      error: -> undefined
      verbose: -> undefined
    }

    context =
      deploymentName: 'development'
      projectRoot: '.'
      localCache:
        millisecondsSince: () -> return 1000
        timestampExists: -> return false
        saveTimestamp: -> return
      skill: { projectInfo: { litexaRoot: 'test/sample'} },
      projectConfig:
        root: '.'
      deploymentOptions:
        awsProfile: 'testProfileThatDoesNotExist'
      deployRoot: 'test/sample'

    lambdaContext =
      codeRoot: 'test/sample'
      litexaRoot: '../../../litexa'
    try
      mkdirp.sync 'test/sample/node_modules'
      mkdirp.sync 'test/sample/lambda'
      fs.closeSync fs.openSync 'test/sample/node_modules/test.txt', 'w'

  afterEach ->
    rimraf.sync 'test/sample' if fs.existsSync('test/sample')

  describe 'Checking function copyNodeModules', ->
    describe 'Testing Windows compatability', ->

    beforeEach ->
      this.originalPlatform = process.platform
      Object.defineProperty process, 'platform', {value: 'win32'}

    afterEach ->
      Object.defineProperty process, 'platform', {value: this.originalPlatform}

    it 'does nothing because no updates are necessary', ->
      context.localCache.millisecondsSince = () -> return 0
      unitTestHelper 'copyNodeModules', context, loggerInterface, lambdaContext
      .then (result) -> expect(result).to.be.undefined
      .catch (error) -> undefined

  describe 'Checking function packZipFile', ->
    describe 'Testing Windows compatability', ->

    beforeEach ->
      this.originalPlatform = process.platform
      Object.defineProperty process, 'platform', {value: 'win32'}

    afterEach ->
      Object.defineProperty process, 'platform', {value: this.originalPlatform}

    it 'creates a zip file with no errors', ->
      context.localCache.millisecondsSince = () -> return 0
      unitTestHelper 'packZipFile', context, loggerInterface, lambdaContext
      .then (result) -> expect(result).to.be.undefined
      .catch (error) -> undefined

  describe 'Checking function checkLambdaPermissions', ->

    beforeEach ->
      artifacts = {
        get: -> return lambdaTriggerStatement.Resource
      }
      context.artifacts = artifacts

    it 'does not add a policy if it finds the alexa trigger policy already attached', ->
      getPolicyPromise = (resolve) ->
        resolve({Policy: "{\"Statement\": [#{JSON.stringify(lambdaTriggerStatement)}]}"})
      awsLambda = {
        getPolicy: -> return {
            promise: -> return new Promise(getPolicyPromise)
          }
        removePermission: () -> return new Promise()
      }
      
      logSpy = spy(loggerInterface, 'log')
      lambdaContext.lambda = awsLambda
      await unitTestHelper 'checkLambdaPermissions', context, loggerInterface, lambdaContext
      assert(logSpy.calledWith(match("reconciling policies against existing data")), 'getPolicy returned data')
      assert(logSpy.withArgs(match("removing policy")).notCalled, 'no policies were removed')

    it 'adds a policy if no policy exists', ->
      getPolicyPromise = (resolve) ->
        throw {
          code: "ResourceNotFoundException"
        }
      addPolicyPromise = (resolve) ->
        resolve("Permission added")
      awsLambda = {
        getPolicy: -> return {
            promise: -> return new Promise(getPolicyPromise)
          }
        removePermission: () -> return new Promise()
        addPermission: -> return {
            promise: -> return new Promise(addPolicyPromise)
          }
      }
      
      logSpy = spy(loggerInterface, 'log')
      verboseSpy = spy(loggerInterface, 'verbose')
      lambdaContext.lambda = awsLambda
      await unitTestHelper 'checkLambdaPermissions', context, loggerInterface, lambdaContext
      assert(logSpy.withArgs(match("reconciling policies")).notCalled, 'there were no existing policies')
      assert(logSpy.calledWith(match("adding policies to Lambda")), 'added policy to Lambda')
      assert(verboseSpy.calledWith(match("addPermission: \"Permission added\"")), 'added a permission')

    it 'adds a policy and removes the old one if there is a mismatch on expected fields', ->
      getPolicyPromise = (resolve) ->
        modifiedLambdaStatement = JSON.parse(JSON.stringify(lambdaTriggerStatement))
        modifiedLambdaStatement.Resource = ""
        resolve({Policy: "{\"Statement\": [#{JSON.stringify(modifiedLambdaStatement)}]}"})
      addPolicyPromise = (resolve) ->
        resolve("Permission added")
      awsLambda = {
        getPolicy: -> return {
            promise: -> return new Promise(getPolicyPromise)
          }
        removePermission: -> return {
            promise: -> return new Promise((resolve) -> resolve())
          }
        addPermission: -> return {
            promise: -> return new Promise(addPolicyPromise)
          }
      }
      
      logSpy = spy(loggerInterface, 'log')
      verboseSpy = spy(loggerInterface, 'verbose')
      lambdaContext.lambda = awsLambda
      await unitTestHelper 'checkLambdaPermissions', context, loggerInterface, lambdaContext
      assert(logSpy.calledWith(match("reconciling policies against existing data")), 'getPolicy returned data')
      assert(logSpy.calledWith(match("removing policy")), 'removed old policy')
      assert(verboseSpy.calledWith(match("addPermission: \"Permission added\"")), 'added a permission')
