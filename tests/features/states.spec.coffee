###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

assert = require 'assert'
preamble = require '../preamble.coffee'

{ expectParse, expectFailParse } = preamble

describe "supports states", ->

  it "recognizes state statements", ->
    expectParse "AState"
    expectParse "AState1"
    expectParse "ASTATE"
    expectParse "astate1then2"
    expectParse "A_State"
    expectParse "launch"
    expectParse "global"
    expectParse "launchCat"
    expectParse "catlaunch"
    expectParse "globalCat"
    expectParse "catglobal"
    expectParse "otherwisecat"
    expectParse "catotherwise"
    expectParse "ifcat"
    expectParse "catif"

  it "reject invalid stateish statements", ->
    expectFailParse "_ASTATE"
    expectFailParse "1State"
    expectFailParse "Statename word"
    expectFailParse "otherwise", "`otherwise` is reserved"
    expectFailParse "if", "`if` is reserved"
    expectFailParse "when", "`when` is reserved"
    expectFailParse "AMAZON.YesIntent", "but \".\" found"
    expectFailParse "otherwis-", "but \"-\" found"
    expectFailParse "otherwise-", "`otherwise` is reserved"
    expectFailParse "otherwise-cat", "`otherwise` is reserved"
    expectFailParse "otherwisecat-", "but \"-\" found"
    expectFailParse """
    otherwisecat
      say "hello"
    otherwisecat-"
    """, "a state named otherwisecat was already defined"

    expectFailParse """
      Statename
        NotAState
    """

  it "catches double state definitions", ->
    expectFailParse """
      SomeState

      SomeState
    """

    expectFailParse
      main: "SomeState"
      other: "SomeState"

    expectParse
      main: "SomeState"
      main_de: "SomeState"

    expectParse
      main: "SomeState"
      main_de: "SomeState"
      main_fr: "SomeState"


  it "validates state transitions", ->
    expectParse """
      launch
        -> other

      other
    """

    expectParse """
      other

      launch
        -> other
    """

    expectFailParse """
      launch
        -> other
    """


    expectParse
      main: """
        launch
          -> elsewhere
      """
      other: """
        elsewhere
      """

    expectParse
      main: """
        launch
          -> elsewhere

        elsewhere
      """
      main_de: """
        other
          -> elsewhere
      """

    expectParse
      main: """
        launch
          -> elsewhere

        elsewhere
      """
      main_de: """
        elsewhere
      """

  it "validates state transitions inside blocks", ->
    # check to see state validator makes it into every kind of block
    expectFailParse """
      launch
        if true
          -> other
    """

    expectFailParse """
      launch
        switch
          == true then
            -> other
    """

    expectFailParse """
      launch
        for a in getArray()
          -> other
    """

    expectParse """
      launch
        if true
          -> other

      other
    """

    expectParse """
      launch
        switch
          == true then
            -> other

      other
    """

    expectParse """
      launch
        for a in getArray()
          -> other

      other
    """

  it "recognizes various state transition statements", ->
    preamble.runSkill 'state-transitions'

  it "traces state transitions", ->
    preamble.runSkill 'state-tracing'
