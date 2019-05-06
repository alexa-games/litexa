
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


chai = require('chai')
chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)
{assert, expect} = chai
{match, spy, stub, mock} = require('sinon')
{deploymentTargetConfiguration} = require('./helpers')

fs = require 'fs'
path = require 'path'
rimraf = require 'rimraf'
mkdirp = require 'mkdirp'
Logs = require('../src/logs')
AwsConfig = require('../src/aws-config')
AWS = require 'aws-sdk'
debug = require('debug')('litexa-logs')

fakeLogStreams =
  logStreams: [
    {
      lastEventTimestamp: (new Date).getTime()
      logStreamName: "logStreamA"
    }
    {
      lastEventTimestamp: (new Date).getTime() - 60 * 60 * 1000
      logStreamName: "logStreamB"
    }
    {
      lastEventTimestamp: (new Date).getTime() + 1000
      logStreamName: "logStreamC"
    }
  ]

fakeLogEvents_streamA =
  events: [
    {
      timestamp: 2000
      message: "START RequestId: d4a1b56d-676a-4d9a-b9d5-cd720e2c697e Version: $LATEST\n"
    }
    {
      timestamp: 3000
      message: "2019-01-31T00:44:19.089Z\td4a1b56d-676a-4d9a-b9d5-cd720e2c697e\tVERBOSE REQUEST {\n  \"type\": \"LaunchRequest\",\n  \"requestId\": \"amzn1.echo-api.request.d3a1606d-57cb-4e54-a202-b398294e48f8\",\n  \"timestamp\": \"2019-01-31T00:44:18Z\",\n  \"locale\": \"en-US\",\n  \"shouldLinkResultBeReturned\": false\n}\n"
    }
    {
      timestamp: 4000
      message: "2019-01-31T00:44:19.439Z\td4a1b56d-676a-4d9a-b9d5-cd720e2c697e\tVERBOSE RESPONSE {\n  \"version\": \"1.0\",\n  \"sessionAttributes\": {\n    \"state\": \"rollcallCount\"\n  },\n  \"response\": {\n    \"shouldEndSession\": false,\n    \"outputSpeech\": {\n      \"type\": \"SSML\",\n      \"ssml\": \"<speak><audio src='https://s3.us-east-1.amazonaws.com/games-prototype-bucket/buttonMonteL2/development/default/Intro-Jingle.mp3'/> Oh, I love this game! We'll need two players for this, we'll call one the Watcher, and the other the Trickster. Before we start: Trickster, how many buttons do you want to use?</speak>\",\n      \"playBehavior\": \"REPLACE_ALL\"\n    },\n    \"reprompt\": {\n      \"outputSpeech\": {\n        \"type\": \"SSML\",\n        \"ssml\": \"<speak>Tell me Trickster, how many buttons should I look for?</speak>\"\n      }\n    },\n    \"card\": {\n      \"type\": \"Standard\",\n      \"title\": \"Step right up to Button Monte!\",\n      \"text\": \"Watcher, keep an eye on the red button. Trickster, shuffle the buttons around. Watcher, as soon as the buttons turn green, press the one you think was the red button.\\nGood luck!\",\n      \"image\": {\n        \"smallImageUrl\": \"https://s3.us-east-1.amazonaws.com/games-prototype-bucket/buttonMonteL2/development/default/title.jpg\",\n        \"largeImageUrl\": \"https://s3.us-east-1.amazonaws.com/games-prototype-bucket/buttonMonteL2/development/default/title.jpg\"\n      }\n    },\n    \"directives\": [\n      {\n        \"type\": \"GadgetController.SetLight\",\n        \"version\": 1,\n        \"targetGadgets\": [],\n        \"parameters\": {\n          \"triggerEvent\": \"none\",\n          \"triggerEventTimeMs\": 0,\n          \"animations\": [\n            {\n              \"targetLights\": [\n                \"1\"\n              ],\n              \"repeat\": 1,\n              \"sequence\": [\n                {\n                  \"color\": \"FFFFFF\",\n                  \"durationMs\": 50,\n                  \"blend\": true\n                },\n                {\n                  \"color\": \"000000\",\n                  \"durationMs\": 500,\n                  \"blend\": true\n                }\n              ]\n            }\n          ]\n        }\n      },\n      {\n        \"type\": \"Display.RenderTemplate\",\n        \"template\": {\n          \"type\": \"BodyTemplate1\",\n          \"backButton\": \"HIDDEN\",\n          \"title\": \"\",\n          \"textContent\": {},\n          \"backgroundImage\": {\n            \"sources\": [\n              {\n                \"url\": \"https://s3.us-east-1.amazonaws.com/games-prototype-bucket/buttonMonteL2/development/default/title.jpg\"\n              }\n            ]\n          }\n        }\n      }\n    ]\n  }\n}\n"
    }
    {
      timestamp: 5000
      message: "END RequestId: d4a1b56d-676a-4d9a-b9d5-cd720e2c697e\n"
    }
    {
      timestamp: 6000
      message: "REPORT RequestId: d4a1b56d-676a-4d9a-b9d5-cd720e2c697e\tDuration: 530.41 ms\tBilled Duration: 600 ms \tMemory Size: 256 MB\tMax Memory Used: 33 MB\t\n"
    }
  ]


describe 'Pull logs from CloudWatch', ->
  cloudwatchInterface = undefined
  loggerInterface = undefined
  logSpy = undefined
  errorSpy = undefined
  describeLogStreamsSpy = undefined
  describeLogStreamsStub = undefined
  getLogEventsSpy = undefined
  getLogEventsStub = undefined
  context = undefined

  beforeEach ->
    loggerInterface = {
      log: -> undefined
      error: -> undefined
    }
    cloudwatchInterface = {
      describeLogStreams: -> { promise: -> new Promise((resolve, reject) -> resolve(fakeLogStreams)) }
      getLogEvents: -> { promise: -> new Promise((resolve, reject) -> resolve(fakeLogEvents_streamA)) }
    }
    cloudwatchInterface.describeLogStreams.promise = () -> undefined

    context =
      deploymentName: 'test'
      projectInfo:
        name: 'sampleProject'
        variant: 'test'
      projectRoot: '.'
      projectConfig:
        root: '.'
      deploymentOptions:
        awsProfile: 'testProfile'
      cloudwatch: cloudwatchInterface
      logsRoot: '.logs'
    fs.writeFileSync 'aws-config.json', JSON.stringify(deploymentTargetConfiguration, null, 2), 'utf8'
    mkdirp.sync('.logs')
    mkdirp.sync('.deploy')

    logSpy = spy(loggerInterface, 'log')
    errorSpy = spy(loggerInterface, 'error')

  afterEach ->
    logSpy.restore()
    errorSpy.restore()
    rimraf.sync('.logs')
    rimraf.sync('.deploy')
    fs.unlinkSync 'aws-config.json'

  it 'pulls logs and formats them to a file correctly', ->
    getLogEventsSpy = spy(cloudwatchInterface, 'getLogEvents')
    describeLogStreamsSpy = spy(cloudwatchInterface, 'describeLogStreams')

    await Logs.pull(context, loggerInterface)

    assert(errorSpy.notCalled, 'logger.error was not called')
    assert(describeLogStreamsSpy.calledOnce, 'describeLogStreams was called once')
    assert(getLogEventsSpy.calledOnce, 'getLogEvents was called once')

    directoryContents = fs.readdirSync path.join context.logsRoot, context.projectInfo.variant
    assert(directoryContents.length == 1, 'a file got written to .logs/test')
    assert(directoryContents[0].endsWith('.log'), 'the written file ends in .log')
    logContents = fs.readFileSync(path.join(context.logsRoot, context.projectInfo.variant, directoryContents[0]), 'utf-8')
    expect(logContents).to.include("requests: ✔ success:1, ✘ fail:0")
    expect(logContents).to.include("--- ✔")
    expect(logContents).to.include("00:02")
    expect(logContents).to.include("\nREQUEST: {")
    expect(logContents).to.include("\nRESPONSE: {")
    expect(logContents).to.not.include("VERBOSE")
    expect(logContents).to.not.include("REPORT")
    expect(logContents).to.not.include("START")

    getLogEventsSpy.restore()
    describeLogStreamsSpy.restore()

  it 'has no log group to pull from', ->
    getLogEventsSpy = spy(cloudwatchInterface, 'getLogEvents')

    describeLogStreamsStub = stub(cloudwatchInterface, 'describeLogStreams').callsFake(() ->
      promise: -> new Promise(() ->
        error = new Error()
        error.code = "ResourceNotFoundException"
        throw error
      )
    )

    await Logs.pull(context, loggerInterface)

    assert(logSpy.calledWith(match("no log records")), 'logger says no log records')
    assert(describeLogStreamsStub.calledOnce, 'describeLogStreams was called once')
    assert(getLogEventsSpy.notCalled, 'did not call getLogEvents')
    directoryContents = fs.readdirSync path.join context.logsRoot, context.projectInfo.variant
    logContents = fs.readFileSync(path.join(context.logsRoot, context.projectInfo.variant, directoryContents[0]), 'utf-8')
    expect(logContents).to.include("requests: ✔ success:0, ✘ fail:0")
    expect(logContents).to.not.include("REQUEST")
    describeLogStreamsStub.restore()

    getLogEventsSpy.restore()

  describe 'path where describeLogStreams throws an error', ->
    beforeEach ->
      describeLogStreamsStub = stub(cloudwatchInterface, 'describeLogStreams').callsFake(() ->
        promise: -> new Promise(() -> throw new Error("Random error"))
      )

    afterEach ->
      describeLogStreamsStub.restore()

    it 'throws an error to stop log pull', ->
      awaitPull = -> await Logs.pull(context, loggerInterface)
      assert.isRejected(awaitPull(), "failed to pull logs", 'log pull threw error')

    it 'verifies the path', ->
      getLogEventsSpy = spy(cloudwatchInterface, 'getLogEvents')

      try
        await Logs.pull(context, loggerInterface)
      catch
        assert true

      assert(describeLogStreamsStub.calledOnce, 'describeLogStreams was called once')
      assert(getLogEventsSpy.notCalled, 'getLogEvents was not called')
      assert(errorSpy.calledOnceWith(match({message: "Random error"})), 'logger.error logs describeLogStreams\'s thrown error')

      getLogEventsSpy.restore()

  describe 'path where getLogEvents throws an error', ->
    beforeEach ->
      describeLogStreamsSpy = spy(cloudwatchInterface, 'describeLogStreams')
      getLogEventsStub = stub(cloudwatchInterface, 'getLogEvents').callsFake(() ->
        promise: -> new Promise(() -> throw new Error("Random error"))
      )
    afterEach ->
      describeLogStreamsSpy.restore()
      getLogEventsStub.restore()

    it 'throws an error to stop log pull', ->
      awaitPull = -> await Logs.pull(context, loggerInterface)
      assert.isRejected(awaitPull(), "failed to pull logs", 'log pull threw error')

    it 'verifies the path', ->
      try
        await Logs.pull(context, loggerInterface)
      catch
        assert true

      assert(describeLogStreamsSpy.calledOnce, 'describeLogStreams was called once')
      assert(getLogEventsStub.calledOnce, 'getLogEvents was called once')
      assert(errorSpy.calledOnceWith(match({message: "Random error"})), 'logger.error logs getLogEvents\'s thrown error')
