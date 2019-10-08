###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

assert = require 'assert'
debug = require('debug')('litexa')
preamble = require '../preamble.coffee'

describe 'supports languages folder overrides', ->
  it 'runs the localization integration test', ->
    preamble.runSkill 'localization'

  it 'builds model with overridden slots correctly', ->
    enUSModel = await preamble.buildSkillModel 'localization', 'en-US'
    usCatBreeds = enUSModel.languageModel.types[0]
    expectedUsCatBreeds = ['american shorthair', 'american curl', 'maine coon']
    testCompleteSlotValuesForIntent(usCatBreeds, expectedUsCatBreeds)

    enGBModel = await preamble.buildSkillModel 'localization', 'en-GB'
    ukCatBreeds = enGBModel.languageModel.types[0]
    expectedUkCatBreeds = ['british shorthair', 'british longhair', 'scottish fold']
    testCompleteSlotValuesForIntent(ukCatBreeds, expectedUkCatBreeds)

    frModel = await preamble.buildSkillModel 'localization', 'fr'
    frCatBreeds = frModel.languageModel.types[0]
    expectedUsCatBreeds = ['american shorthair', 'american curl', 'maine coon'] # uses default
    testCompleteSlotValuesForIntent(frCatBreeds, expectedUsCatBreeds)

  it 'eliminates intent handlers that do not exist in the overridden state', ->
    frModel = await preamble.buildSkillModel 'localization', 'fr'
    intents = frModel.languageModel.intents.map (intent) -> intent.name
    assert("CAT" not in intents)

  testCompleteSlotValuesForIntent = (actualSlots, expectedSlots) ->
    for slotValue in actualSlots.values
      assert(slotValue.name.value in expectedSlots)
      expectedSlots.splice(expectedSlots.indexOf(slotValue.name.value), 1)
    assert(expectedSlots.length == 0)
