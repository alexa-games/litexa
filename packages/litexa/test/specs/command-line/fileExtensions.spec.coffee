
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


{expect} = require('chai')

fileExtensions = require('@src/command-line/fileExtensions')

describe 'extensions', ->
  it 'supports JavaScript', ->
    expect(fileExtensions['javascript']).to.equal('js')

  it 'supports CoffeeScript', ->
    expect(fileExtensions['coffee']).to.equal('coffee')

  it 'supports JSON', ->
    expect(fileExtensions['json']).to.equal('json')

  it 'supports TypeScript', ->
    expect(fileExtensions['typescript']).to.equal('ts')
