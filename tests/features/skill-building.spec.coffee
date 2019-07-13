###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

assert = require 'assert'
debug = require('debug')('litexa')
path = require 'path'

{ fake } = require 'sinon'

build = require '@litexa/core/src/command-line/skill-builder'
config = require '@litexa/core/src/command-line/project-config'

describe 'supports building a skill', ->
  root = path.join __dirname, '..', 'data', 'simple-skill'

  it 'validates skill names', ->
    fakeValidator = fake.returns false
    await config.loadConfig root, fakeValidator
    assert.equal true, fakeValidator.calledOnce

  it 'finds the config file in the same directory', ->
    loaded = await config.loadConfig root
    assert.ok loaded?
    assert.equal 'simpleSkillTest', loaded.name

  it 'finds the config file in a parent directory', ->
    loaded = await config.loadConfig root
    assert.ok loaded?
    assert.equal 'simpleSkillTest', loaded.name

  it 'builds a skill', ->
    skill = await build.build root
