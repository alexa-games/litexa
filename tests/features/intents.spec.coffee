###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

assert = require 'assert'
debug = require('debug')('litexa')
{runSkill, expectParse, expectFailParse, buildSkillModel} = require '../preamble.coffee'

describe 'supports intent statements', ->
  it 'runs the intents integration test', ->
    runSkill 'intents'

  it 'runs the one shot integration test', ->
    runSkill 'one-shot'

  it 'does not allow wrong indentation of intents', ->
    expectParse """
    waitForResponse
      say "hello"
      when AMAZON.YesIntent
        say "yes"

      when AMAZON.NoIntent
        say "no"
      say "post processor"
    """

    expectFailParse """
    waitForResponse
      when AMAZON.YesIntent
        say "hello"

        when AMAZON.NoIntent
          say "hi"
    """

    expectFailParse """
    waitForResponse
      say "howdy."

      when AMAZON.YesIntent
        say "hello"
        if 3 > 1
          when AMAZON.YesIntent
            say "meow"
          when AMAZON.NoIntent
            say "bork"
    """

    expectFailParse """
    waitForResponse
      say "howdy."

      when "nested level"
        say "hello"
        if 3 > 1
          if 4 > 3
            say "one more nested level"
            when "another level"
              say "meow"
            when AMAZON.NoIntent
              say "bork"
    """

    expectFailParse """
    someState
      when "hi"
        say "hi"
    when "imposter state"
      say "hello"
    """

  it 'does not allow duplicate intents that are not event/name-specific in the same state', ->
    expectParse """
    someState
      when "yes"
        say "wahoo"
      when AMAZON.NoIntent
        say "aww"

    anotherState
      when "yes"
        or "yea"
        say "wahoo"
      when AMAZON.NoIntent
        say "aww"
    """

    expectFailParse """
    someState
      when "meow"
        or "mreow"
        say "meow meow"
      when AMAZON.NoIntent
        say "aww"
      when "Meow"
        say "meow meow"
    """, "redefine intent `MEOW`"

    expectFailParse """
    waitForAnswer
      when "Yea"
        or "yes"
        say "You said"

      when AMAZON.NoIntent
        say "You said"

      when AMAZON.NoIntent
        say "no."
    """, "redefine intent `AMAZON.NoIntent`"

    expectParse """
    global
      when AMAZON.StopIntent
        say "Goodbye."
        END

      when AMAZON.CancelIntent
        say "Bye."
        END

      when AMAZON.StartOverIntent
        say "No."
        END
    """

    expectFailParse """
    global
      when AMAZON.StopIntent
        say "Goodbye."
        END

      when AMAZON.CancelIntent
        say "Bye"

      when AMAZON.StartOverIntent
        say "No."
        END

      when AMAZON.CancelIntent
        say "bye."
        END
    """

    expectFailParse """
    global
      when AMAZON.YesIntent
        say "Goodbye."
        END

      when AMAZON.CancelIntent
        say "Bye"

      when AMAZON.StartOverIntent
        say "No."
        END

      when AMAZON.YesIntent
        say "bye."
        END
    """

  it 'does allow multiple name-specific intents in the same state', ->
    expectParse """
    global
      when Connections.Response
        say "Connections.Response"

      when Connections.Response "Buy"
        say "upsell Connections.Response"

      when Connections.Response "Cancel"
        say "upsell Connections.Response"

      when Connections.Response "Upsell"
        say "upsell Connections.Response"

      when Connections.Response "Unknown"
        say "unknown Connections.Response"
    """

  it 'does not allow plain utterances being reused in different intent handlers', ->
    # when <utterance> + or <utterance>
    expectFailParse """
    global
      when "walk"
        or "run"
        say "moving"

      when "run"
        say "running"
    """, "utterance 'run' in the intent handler for 'RUN' was already handled by the intent
      'WALK'"

    # or <utterance> + or <utterance>
    expectFailParse """
    global
      when "walk"
        or "run"
        say "moving"

      when "sprint"
        or "run"
        say "running"
    """, "utterance 'run' in the intent handler for 'SPRINT' was already handled by the intent
      'WALK'"

    #  or <Utterance> + or <uTTERANCE>
    expectFailParse """
    global
      when "walk"
        or "Run"
        say "moving"

      when "sprint"
        or "rUN"
        say "running"
    """, "utterance 'run' in the intent handler for 'SPRINT' was already handled by the intent
      'WALK'"

  it 'does allow reusing otherwise identical utterances with different slot variables', ->
    expectParse """
    global
      when "wander"
        or "walk the $cheagle today"
        with $cheagle = "Coco"
        say "walking"

      when "stroll"
        or "walk the $poodle today"
        with $poodle = "Princess"
        say "running"
    """

  it 'does not allow reusing identical utterances with identical slot variables', ->
    expectFailParse """
    global
      when "wander"
        or "walk the $Dog today"
        with $Dog = "Lassie"
        say "walking"

      when "stroll"
        or "walk the $Dog today"
        say "running"
    """, "utterance 'walk the $Dog today' in the intent handler for 'STROLL' was already handled by
      the intent 'WANDER'"

  it 'does not allow reusing intents when listed as parent handlers (multi-intent handlers)', ->
    expectFailParse """
    global
      when AMAZON.YesIntent
        say "hello"

      when AMAZON.YesIntent
        or AMAZON.NextIntent
        say "hi"
    """, "Not allowed to redefine intent `AMAZON.YesIntent` in state `global`"

  it 'does not allow reusing intents when aggregated with another handler (multi-intent handlers)', ->
    expectFailParse """
    global
      when AMAZON.YesIntent
        say "hello"

      when AMAZON.NextIntent
        or AMAZON.YesIntent
        say "hi"
    """, "Not allowed to redefine intent `AMAZON.YesIntent` in state `global`"

  it 'does not allow parenting itself (multi-intent handlers)', ->
    expectFailParse """
    global
      when AMAZON.YesIntent
        or AMAZON.YesIntent
        say "hi"
    """, "Not allowed to redefine intent `AMAZON.YesIntent` in state `global`"

  it 'does not allow reusing intents when it is aggregated with 2 different handlers (multi-intent handlers)', ->
    expectFailParse """
    global
      when AMAZON.YesIntent
        or AMAZON.HelpIntent
        say "hello"

      when AMAZON.NoIntent
        or AMAZON.HelpIntent
        say "hi"
    """, "Not allowed to redefine intent `AMAZON.HelpIntent` in state `global`"

  it 'does not allow declaring utterances in multi-intent handlers', ->
    expectFailParse """
    global
      when AMAZON.YesIntent
        or AMAZON.HelpIntent
        or "hello intent"
        say "hello"
    """, "Can't add this utterance as an 'or' alternative here because this handler already specifies multiple intents. Add the alternative to one of the original intent declarations instead."

  it 'does not allow creating multi-intent handlers if utterances exist', ->
    expectFailParse """
    global
      when AMAZON.YesIntent
        or "hello intent"
        or AMAZON.HelpIntent
        say "hello"
    """, "Can't add intent name `AMAZON.HelpIntent` as an `or` alternative to `AMAZON.YesIntent` because it already has utterance alternatives"

  it 'allows separately declaring utterances in other states and utterances for when handlers (multi-intent handlers)', ->
    expectParse """
    stateA
      when HelloIntent
        or "hello there"

      when MEOW
        or "meow meow"

      when AMAZON.RepeatIntent
        or AMAZON.NextIntent

    global
      when HelloIntent
        or AMAZON.NoIntent

      when "meow"
        or AMAZON.YesIntent

      when AMAZON.RepeatIntent
        or "rephrase that"
    """

  model = null
  intentNames = null
  it 'compiles the intents test skill', ->
    model = await buildSkillModel 'intents'
    intentNames = model.languageModel.intents.map (intent) -> intent.name

  it 'creates a skill model that includes child intents of multi-intent handlers', ->
    assert("PreviouslyNotDefinedIntentName" in intentNames, 'PreviouslyNotDefinedIntentName exists in model')
    assert("AMAZON.NoIntent" in intentNames, 'AMAZON.NoIntent did not exist in model')
    assert("OtherIntentName" in intentNames, 'OtherIntentName did not exist in model')

  it 'includes unextended built in Amazon intents', ->
    intent = null 
    for v in model.languageModel.intents
      intent = v if v.name == "AMAZON.YesIntent"
    assert( intent != null, 'AMAZON.YesIntent was not included in the model' )
    assert( intent.samples.length == 0, 'AMAZON.YesIntent had sample utterances when it should not' )

  it 'extends built in Amazon intents', ->
    intent = null 
    for v in model.languageModel.intents
      intent = v if v.name == "AMAZON.StopIntent"
    assert("no really stop" in intent.samples, '`no really stop` was not added to the intent')
    assert("definitely stop" in intent.samples, '`definitely stop` was not added to the intent')
    
