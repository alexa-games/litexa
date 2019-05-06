
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


{expect} = require 'chai'
render = require '@src/command-line/generators/searchReplace'

describe '#searchReplace', ->
  it 'replaces the placeholders in the string data with the provided values', ->
    stringTemplate = 'Hi, my name is {name}, I am {age} years old. I am {sentiment} to meet you, very {sentiment}.'
    templateValues =
      name: 'Alexa'
      age: 4
      sentiment: 'pleased'

    renderedString = render(stringTemplate, templateValues)
    expectedResult = 'Hi, my name is Alexa, I am 4 years old. I am pleased to meet you, very pleased.'

    expect(renderedString).to.equal(expectedResult)
