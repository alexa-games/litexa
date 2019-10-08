###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

require '@src/getter.polyfill'
{expect} = require 'chai'

describe '@getter', ->
  it 'allows me to use the @getter syntax to polyfill ES6 getter behavior', ->
    attribute = 'myAttribute'
    value = 'expectedValue'

    class TestClass
      @getter attribute, ->
        value

    testInstance = new TestClass()
    expect(testInstance.myAttribute).to.equal(value)
