
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


chai = require 'chai'
{ expect } = chai
{ assert, match, stub } = require 'sinon'

LoggingChannel = require '@src/command-line/loggingChannel'
smapi = require '@src/command-line/api/smapi'

describe 'Spawning ASK CLI command to call SMAPI', ->
  args = {}
  errorStub = undefined
  spawnStub = undefined

  beforeEach ->
    args.askProfile = undefined
    args.command = undefined

    errorStub = stub(console, 'error')
    fakeSpawn = (cmd, args) -> Promise.resolve({ stdout: '', stderr: '' })
    spawnStub = stub(smapi, 'spawnPromise').callsFake(fakeSpawn)

  afterEach ->
    errorStub.restore()
    spawnStub.restore()

  it 'errors on missing command', ->
    args.askProfile = 'myProfile'
    expect () ->
      smapi.call args
    .to.throw(Error, "called without a command")

  it 'errors on missing ASK profile', ->
    args.command = '--help'

    expect () ->
      smapi.call args
    .to.throw(Error, "missing an ASK profile")

  it 'spawns correct CLI output for given command/params', ->
    args.askProfile = 'mockProfileId'
    args.command = 'associate-isp'
    args.params = {
      'isp-id': 'mockIspId'
      'skill-id': 'mockSkillId'
    }

    smapi.call args
    expectedArgs = [
      'api',
      'associate-isp',
      '--profile',
      'mockProfileId',
      '--isp-id',
      'mockIspId',
      '--skill-id',
      'mockSkillId'
    ]
    assert.calledWithExactly(spawnStub, 'ask', expectedArgs)
