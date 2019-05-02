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
