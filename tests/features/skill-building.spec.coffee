
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
