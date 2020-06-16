###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

chai = require 'chai'
{ expect } = chai
{ assert, match, stub } = require 'sinon'
chai.use require 'chai-as-promised'

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
    expect smapi.call args
    .to.be.rejectedWith(Error, "called without a command")

  it 'errors on missing ASK profile', ->
    args.command = '--help'

    expect smapi.call args
    .to.be.rejectedWith(Error, "missing an ASK profile")

  it 'spawns correct CLI output for given command/params', ->
    args.askProfile = 'mockProfileId'
    args.command = 'associate-isp'
    args.params = {
      'isp-id': 'mockIspId'
      'skill-id': 'mockSkillId'
    }

    logger = new LoggingChannel {}
    smapi.prepare logger
    .then ->
      smapi.call args
    .then ->
      if smapi.version.major < 2
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
      else
        expectedArgs = [
          'smapi',
          'associate-isp',
          '--profile',
          'mockProfileId',
          '--isp-id',
          'mockIspId',
          '--skill-id',
          'mockSkillId'
        ]

      assert.calledWithExactly(spawnStub, 'ask', expectedArgs)