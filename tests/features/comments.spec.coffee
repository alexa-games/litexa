
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

describe 'build the comments skill', ->
  it 'should validate skill name', ->
    root = path.join __dirname, '..', 'data', 'comments'
    fakeValidator = fake.returns false
    await config.loadConfig root, fakeValidator
    assert.equal true, fakeValidator.calledOnce

  it 'should find the config file in the same directory', ->
    root = path.join __dirname, '..', 'data', 'comments'
    loaded = await config.loadConfig root
    assert.ok loaded?
    assert.equal 'commentTests', loaded.name

  it 'should build the comments skill successfully', ->
    root = path.join __dirname, '..', 'data', 'comments'
    skill = await build.build root
