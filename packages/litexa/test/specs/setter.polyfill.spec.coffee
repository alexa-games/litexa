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
