
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
preamble = require '../preamble.coffee'

describe 'supports deploy variables and excluding blocks with them', ->
  it 'runs the deploy variables integration test', ->
    preamble.runSkill 'deploy-variables'

  it 'builds the model taking into account postfix conditionals on intent handlers', ->
    languageModel = await preamble.buildSkillModel 'deploy-variables', 'default'
    nameIsIncludedCorrectly = (intent) =>
      return ['HELLO', 'HELLO_BOB', 'POSITIVE_INCLUSION', 'GO_TO_TUNNEL', 'HELLO_UNLESS_ROGER',
        'AMAZON.StopIntent', 'AMAZON.CancelIntent', 'AMAZON.StartOverIntent', 'AMAZON.NavigateHomeIntent']
        .includes(intent.name);

    nameIsExcludedCorrectly = (intent) =>
      return !['HELLO_ROGER', 'NEGATIVE_INCLUSION', 'HELLO_UNLESS_BOB'].includes(intent.name);

    assert(languageModel.languageModel.intents.every(nameIsIncludedCorrectly), 'No included intents were left out of the model')
    assert(languageModel.languageModel.intents.every(nameIsExcludedCorrectly), 'No excluded intents were in the model')
