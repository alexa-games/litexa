###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

assert = require 'assert'
debug = require('debug')('says')
path = require 'path'
parser = require '@litexa/core/src/parser/parser'
preamble = require '../preamble.coffee'

{ VariableScopeManager } = require '@litexa/core/src/parser/variableScope'


makeUtterance = (fragment) ->
  result = await parser.parseFragment "when \"#{fragment}\" "
  intent = result[0]
  return intent.utterances[0]

assertUtterances = (utterance, outcomes) ->
  result = utterance.toUtterance()
  try
    assert.deepEqual result, outcomes
  catch err
    utterance.visit 0, (depth, part) ->
      console.log "#{depth} #{part}"
    throw err




describe 'parses utterances', ->

    it 'parses a simple string', ->
      text = "somethin' the user might say"
      utterance = await makeUtterance text
      assertUtterances utterance, [ "somethin' the user might say" ]


    it 'parses with string, slot parts', ->
      utterance = await makeUtterance "I said $something"
      assertUtterances utterance, [ "i said {something}" ]


    it 'parses with string, slot, string parts', ->
      utterance = await makeUtterance "I said $something to them"
      assertUtterances utterance, [ "i said {something} to them" ]


    it 'parses with string, slot, string, slot parts', ->
      utterance = await makeUtterance "I said $something to $someone"
      assertUtterances utterance, [ "i said {something} to {someone}" ]


    it 'parses a group with one part', ->
      utterance = await makeUtterance "(I said that)"
      assertUtterances utterance, [ "i said that" ]


    it 'parses successive one part groups', ->
      utterance = await makeUtterance "(I said this)(,and that)"
      assertUtterances utterance, [ "i said this,and that" ]


    it 'parses successive one part groups separated by text', ->
      utterance = await makeUtterance "(I said this), (and that)"
      assertUtterances utterance, [ "i said this, and that" ]


    it 'parses successive one part groups separated by a slot', ->
      utterance = await makeUtterance "(I said this) $connector (and that)"
      assertUtterances utterance, [ "i said this {connector} and that" ]


    it 'parses a group with mixed parts', ->
      utterance = await makeUtterance "(I said $something to $someone)"
      assertUtterances utterance, [ "i said {something} to {someone}" ]


    it 'parses nested groups', ->
      utterance = await makeUtterance "(I said this (and that))"
      assertUtterances utterance, [ "i said this and that" ]


    it 'parses a simple alternation', ->
      utterance = await makeUtterance "this|that"
      assertUtterances utterance, [ "this", "that" ]


    it 'parses repeated alternations', ->
      utterance = await makeUtterance "this|that|the|other"
      assertUtterances utterance, [ "this", "that", "the", "other" ]


    it 'parses an alternation inside a group', ->
      utterance = await makeUtterance "(this|that)"
      assertUtterances utterance, [ "this", "that" ]


    it 'parses repeat alternations inside a group', ->
      utterance = await makeUtterance "(this|that|other)"
      assertUtterances utterance, [ "this", "that", "other" ]


    it 'combines a prefix string with a grouped alternation', ->
      utterance = await makeUtterance "hello (you|there)"
      assertUtterances utterance, ["hello you", "hello there"]


    it 'permutes across two alternations', ->
      utterance = await makeUtterance "(hello|hi) (you|there)"
      assertUtterances utterance, ["hello you", "hello there", "hi you", "hi there"]


    it 'combines strings and alternations', ->
      utterance = await makeUtterance "I say (hello|hi), (you|there)"
      assertUtterances utterance, [
        "i say hello, you"
        "i say hello, there"
        "i say hi, you"
        "i say hi, there"
      ]

    it 'permutes over three alternations', ->
      utterance = await makeUtterance "(I|we) would (like|need) to (come|go)"
      assertUtterances utterance, [
        "i would like to come"
        "i would like to go"
        "i would need to come"
        "i would need to go"
        "we would like to come"
        "we would like to go"
        "we would need to come"
        "we would need to go"
      ]

    it 'permutes over nested alternations', ->
      utterance = await makeUtterance "I want (a coin|(some|many|all the) coins)"
      assertUtterances utterance, [
        "i want a coin"
        "i want some coins"
        "i want many coins"
        "i want all the coins"
      ]

    it 'parses slot references', ->
      utterance = await makeUtterance "Hello $name"
      assertUtterances utterance, [ "hello {name}" ]


    it 'parses slot references in groups', ->
      utterance = await makeUtterance "(Hello $name)"
      assertUtterances utterance, [ "hello {name}" ]


    it 'parses slot references alongside alternations', ->
      utterance = await makeUtterance "(Hello|Hi) $name"
      assertUtterances utterance, [ "hello {name}", "hi {name}" ]


    it 'parses slot references in alternations', ->
      utterance = await makeUtterance "Hello $name|Hi there"
      assertUtterances utterance, [ "hello {name}", "hi there" ]

    it 'runs the utterance variance integration test', ->
      preamble.runSkill 'utterance-variance'
