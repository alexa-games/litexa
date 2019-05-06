
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


require '@src/setter.polyfill'
{expect} = require 'chai'

describe '@setter', ->
  it 'allows me to use the @setter syntax to polyfill ES6 setter behavior', ->
    attribute = 'myAttribute'
    value = 'expectedValue'

    class TestClass
      @setter attribute, (value) ->
        @setAttribute = value

    testInstance = new TestClass()
    testInstance.myAttribute = value
    expect(testInstance.setAttribute).to.equal(value)
