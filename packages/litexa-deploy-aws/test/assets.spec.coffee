
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


{assert, expect} = require('chai')
{match, spy, stub} = require('sinon')

Assets = require('../src/assets')

describe 'Deploys S3 Bucket and asset-related things', ->
  loggerInterface = undefined
  context = undefined

  it 'allows valid S3 bucket names', ->
    validS3BucketNames = [
      "aaa", "a.a--a.a", "a.a.a.a", "a.a.a-a", "1.1.1.1a",
      "a1.1.1", "a.1.1.a", "1.a.a.1", "1a1.1"
    ]
    for name in validS3BucketNames
      validate = -> Assets.testing.validateS3BucketName(name)
      expect(validate).to.not.throw()


  it 'throws an exception for invalid S3 bucket names', ->
    invalidS3BucketNames = [
      "a-a-a-a-", "a.a.a.", "a.a.-", "a.a.a-", "313.1"
    ]
    for name in invalidS3BucketNames
      validate = -> Assets.testing.validateS3BucketName(name)
      expect(validate).to.throw("does not follow the rules")
