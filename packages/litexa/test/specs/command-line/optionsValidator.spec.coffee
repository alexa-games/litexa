
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


{assert, expect} = require 'chai'
validator = require '@src/command-line/optionsValidator'

describe 'OptionsValidator', ->
  toValidate = undefined

  beforeEach ->
    toValidate = [{
      name: 'option'
      valid: [
        'yes'
        'no'
        'maybe'
      ]
      message: 'option has to be of value "yes", "no", or "maybe"'
    }]

  it 'returns an error', ->
    result = validator({ option: 'mybae' }, toValidate)
    expect(result).to.deep.equal([{
      name: 'option'
      message: 'option has to be of value "yes", "no", or "maybe"'
    }])

  it 'does not return an error', ->
    result = validator({ option: 'maybe' }, toValidate)
    assert result.length == 0, 'it does not return any errors'

  it 'does not remove invalid option from object', ->
    options = { option: 'mybae' }
    validator(options, toValidate)
    expect(options).to.deep.equal({ option: 'mybae' })

  it 'does removes invalid option from object', ->
    options = { option: 'mybae' }
    validator(options, toValidate, true)
    expect(options).to.deep.equal({})

  it 'accepts empty options', ->
    result = validator({}, toValidate)
    assert result.length == 0, 'it does not return any errors'
