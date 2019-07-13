###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

{ assert, expect } = require('chai')
{ match, spy, stub } = require('sinon')

{ collectUploadInfo
  listBucketAndUploadAssets
  prepareBucket
  validateS3BucketName
  validateS3PathName } = require('../../src/utils/s3Utils')

describe 'Deploys S3 Bucket and asset-related things', ->
  fakeLogger = { log: -> }
  skillContext = undefined

  beforeEach = ->
    skillContext = undefined

  it 'allows valid S3 bucket names', ->
    validS3BucketNames = [
      "aaa", "a.a--a.a", "a.a.a.a", "a.a.a-a", "1.1.1.1a",
      "a1.1.1", "a.1.1.a", "1.a.a.1", "1a1.1"
    ]
    for name in validS3BucketNames
      validate = -> validateS3BucketName(name)
      expect(validate).to.not.throw()

  it 'throws an exception for invalid S3 bucket names', ->
    invalidS3BucketNames = [
      "a-a-a-a-", "a.a.a.", "a.a.-", "a.a.a-", "313.1"
    ]
    for name in invalidS3BucketNames
      validate = -> validateS3BucketName(name)
      expect(validate).to.throw("does not follow the rules")

  it 'adds a default file to languages missing the file', ->
    skillContext = {
      artifacts: {
        save: ->
        delete: ->
      }
      skill: {
        projectInfo: {
          languages: {
            default: {
              assets: {
                root: "defaultRoot"
                files: [ "defaultFile", "icon-108.png", "icon-512.png" ]
              }
              convertedAssets: {
                root: "defaultConvertedRoot"
                files: [ "defaultConvertedFile" ]
              }
            }
            de: {
              assets: {
                root: "deRoot"
                files: [ "icon-108.png" ]
              }
              convertedAssets: {
                root: "deConvertedRoot"
                files: []
              }
            }
          }
        }
      }
    }

    fakeMD5 = {
      sync: (fileName) ->
        return "1234567890"
    }
    s3Context = {
      baseLocation: "base"
      RESTRoot: 'https://s3.myRegion.amazonaws.com/myBucketName'
      assets: {}
    }

    expectedS3Context = {
      baseLocation: s3Context.baseLocation
      RESTRoot: s3Context.RESTRoot
      assets: {
        'base/default/defaultFile': {
          name: 'defaultFile'
          sourceFilename: 'defaultRoot/defaultFile'
          md5: '1234567890'
          md5Brief: '34567890'
          needsUpload: true
        }
        'base/default/icon-108.png': {
          name: 'icon-108.png'
          sourceFilename: 'defaultRoot/icon-108.png'
          md5: '1234567890'
          md5Brief: '34567890'
          needsUpload: true
        }
        'base/default/icon-512.png': {
          name: 'icon-512.png'
          sourceFilename: 'defaultRoot/icon-512.png'
          md5: '1234567890'
          md5Brief: '34567890'
          needsUpload: true
        }
        'base/default/defaultConvertedFile': {
          name: 'defaultConvertedFile'
          sourceFilename: 'defaultConvertedRoot/defaultConvertedFile'
          md5: '1234567890'
          md5Brief: '34567890'
          needsUpload: true
        }
        'base/de/defaultFile': {
          name: 'defaultFile'
          sourceFilename: 'defaultRoot/defaultFile'
          md5: '1234567890'
          md5Brief: '34567890'
          needsUpload: true
        }
        'base/de/icon-108.png': {
          name: 'icon-108.png'
          sourceFilename: 'deRoot/icon-108.png'
          md5: '1234567890'
          md5Brief: '34567890'
          needsUpload: true
        }
        'base/de/icon-512.png': {
          name: 'icon-512.png'
          sourceFilename: 'defaultRoot/icon-512.png'
          md5: '1234567890'
          md5Brief: '34567890'
          needsUpload: true
        }
        'base/de/defaultConvertedFile': {
          name: 'defaultConvertedFile'
          sourceFilename: 'defaultConvertedRoot/defaultConvertedFile'
          md5: '1234567890'
          md5Brief: '34567890'
          needsUpload: true
        }
      }
      assetCount: 8,
      deployedIconAssets: {
        default: {
          "icon-108.png": {
            md5: "1234567890"
            url: "#{s3Context.RESTRoot}/base/default/icon-108.png"
          }
          "icon-512.png": {
            md5: "1234567890"
            url: "#{s3Context.RESTRoot}/base/default/icon-512.png"
          }
        }
        de: {
          "icon-108.png": {
            md5: "1234567890"
            url: "#{s3Context.RESTRoot}/base/de/icon-108.png"
          }
          "icon-512.png": {
            md5: "1234567890"
            url: "#{s3Context.RESTRoot}/base/de/icon-512.png"
          }
        }
      }
    }

    collectUploadInfo({ s3Context, skillContext, logger: fakeLogger, md5Override: fakeMD5 })
    expect(s3Context).to.deep.equal(expectedS3Context)
