###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

{ assert, expect } = require('chai')
{ match, spy, stub } = require('sinon')

{ collectUploadInfo
  createAssetSets
  findAndRegisterFilesToUpload
  uploadAssetSet
  validateS3BucketName } = require('../../src/utils/s3Utils')

describe 'S3Utils', ->

  describe 'Deploys S3 Bucket and asset-related things', ->
    fakeLogger = { log: -> }
    skillContext = undefined

    beforeEach ->
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
            firstTimeUpload: true
            name: 'defaultFile'
            sourceFilename: 'defaultRoot/defaultFile'
            md5: '1234567890'
            md5Brief: '34567890'
            needsUpload: true
          }
          'base/default/icon-108.png': {
            firstTimeUpload: true
            name: 'icon-108.png'
            sourceFilename: 'defaultRoot/icon-108.png'
            md5: '1234567890'
            md5Brief: '34567890'
            needsUpload: true
          }
          'base/default/icon-512.png': {
            firstTimeUpload: true
            name: 'icon-512.png'
            sourceFilename: 'defaultRoot/icon-512.png'
            md5: '1234567890'
            md5Brief: '34567890'
            needsUpload: true
          }
          'base/default/defaultConvertedFile': {
            firstTimeUpload: true
            name: 'defaultConvertedFile'
            sourceFilename: 'defaultConvertedRoot/defaultConvertedFile'
            md5: '1234567890'
            md5Brief: '34567890'
            needsUpload: true
          }
          'base/de/defaultFile': {
            firstTimeUpload: true
            name: 'defaultFile'
            sourceFilename: 'defaultRoot/defaultFile'
            md5: '1234567890'
            md5Brief: '34567890'
            needsUpload: true
          }
          'base/de/icon-108.png': {
            firstTimeUpload: true
            name: 'icon-108.png'
            sourceFilename: 'deRoot/icon-108.png'
            md5: '1234567890'
            md5Brief: '34567890'
            needsUpload: true
          }
          'base/de/icon-512.png': {
            firstTimeUpload: true
            name: 'icon-512.png'
            sourceFilename: 'defaultRoot/icon-512.png'
            md5: '1234567890'
            md5Brief: '34567890'
            needsUpload: true
          }
          'base/de/defaultConvertedFile': {
            firstTimeUpload: true
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

  describe '#createAssetSets()', ->
    skillContext = undefined
    s3Context = undefined

    beforeEach ->
      skillContext = {
        deploymentOptions: {
          s3Configuration: {
            bucketName: 'myBucketName'
          }
        }
      }
      s3Context = {
        uploads: [
          { name: 'audio1.mp3' },
          { name: 'audio2.mp3' },
          { name: 'audio3.mp3' },
          { name: 'image1.jpg' },
          { name: 'image2.jpg' },
          { name: 'style.css' },
          { name: 'index.html' },
          { name: 'error.html' },
          { name: 'main.js' }
        ]
      }

    it 'should throw an error if a params uses one or more keys that are reserved by Litexa', ->
      skillContext.deploymentOptions.s3Configuration.uploadParams = [{
        params: {
            Key: 'myKey'  # "Key" is a reserved key name
          }
        }]

      expect(() -> createAssetSets { s3Context, skillContext }).to.throw()

    it 'should produce only one asset set with all assets inside if object properties is not defined', ->
      delete skillContext.deploymentOptions.s3Configuration.uploadParams
      assetSets = createAssetSets { s3Context, skillContext }

      expect(assetSets.length).to.equal(1)

      assetNames = []
      for asset in assetSets[0].assets
        assetNames.push asset.name
      expect(assetNames).to.have.all.members([
        'style.css', 'main.js'
        'audio1.mp3', 'audio2.mp3', 'audio3.mp3',
        'image1.jpg', 'image2.jpg',
        'index.html', 'error.html'])
      expect(assetSets[0].params).to.equal(undefined)

    it 'should produce only one asset set with all assets inside if object properties is undefined', ->
      skillContext.deploymentOptions.s3Configuration.uploadParams = undefined
      assetSets = createAssetSets { s3Context, skillContext }

      expect(assetSets.length).to.equal(1)

      assetNames = []
      for asset in assetSets[0].assets
        assetNames.push asset.name
      expect(assetNames).to.have.all.members([
        'style.css', 'main.js'
        'audio1.mp3', 'audio2.mp3', 'audio3.mp3',
        'image1.jpg', 'image2.jpg',
        'index.html', 'error.html'])
      expect(assetSets[0].params).to.equal(undefined)

    it 'should produce only one asset set with all assets inside if object properties is an empty list', ->
      skillContext.deploymentOptions.s3Configuration.uploadParams = []
      assetSets = createAssetSets { s3Context, skillContext }

      expect(assetSets.length).to.equal(1)

      assetNames = []
      for asset in assetSets[0].assets
        assetNames.push asset.name
      expect(assetNames).to.have.all.members([
        'style.css', 'main.js'
        'audio1.mp3', 'audio2.mp3', 'audio3.mp3',
        'image1.jpg', 'image2.jpg',
        'index.html', 'error.html'])
      expect(assetSets[0].params).to.equal(undefined)

    it 'should produce one asset set with all assets inside if only one object property is defined for all assets', ->
      skillContext.deploymentOptions = {
        s3Configuration: {
          uploadParams: [
            {
              params: {
                CacheControl: 'max-age=3600'
              }
            }
          ]
        }
      }

      assetSets = createAssetSets { s3Context, skillContext }

      expect(assetSets.length).to.equal(1)

      assetNames = []
      for asset in assetSets[0].assets
        assetNames.push asset.name
      expect(assetNames).to.have.all.members([
        'style.css', 'main.js'
        'audio1.mp3', 'audio2.mp3', 'audio3.mp3',
        'image1.jpg', 'image2.jpg',
        'index.html', 'error.html'])
      expect(assetSets[0].params.CacheControl).to.equal('max-age=3600')

    it 'should produce N asset sets if N object properties are defined that together cover all of the available assets', ->
      skillContext.deploymentOptions = {
        s3Configuration: {
          uploadParams: [
            {
              filter: ['*.mp3', '*.jpg']
              params: {
                CacheControl: 'max-age=3600'
              }
            },
            {
              filter: ['*.html', '*.js'],
              params: {
                CacheControl: 'no-cache'
              }
            },
            {
              params: {
                CacheControl: 'max-age=600'
              }
            }
          ]
        }
      }

      assetSets = createAssetSets { s3Context, skillContext }

      expect(assetSets.length).to.equal(3)

      assetNames = []
      for asset in assetSets[0].assets
        assetNames.push asset.name
      expect(assetNames).to.have.all.members(['audio1.mp3', 'audio2.mp3', 'audio3.mp3', 'image1.jpg', 'image2.jpg'])
      expect(assetSets[0].params.CacheControl).to.equal('max-age=3600')

      assetNames = []
      for asset in assetSets[1].assets
        assetNames.push asset.name
      expect(assetNames).to.have.all.members(['index.html', 'error.html', 'main.js'])
      expect(assetSets[1].params.CacheControl).to.equal('no-cache')

      assetNames = []
      for asset in assetSets[2].assets
        assetNames.push asset.name
      expect(assetNames).to.have.all.members(['style.css'])
      expect(assetSets[2].params.CacheControl).to.equal('max-age=600')

    it 'should produce N asset sets if N-1 object properties are defined that together cover all but one of the available N asset sets', ->
      skillContext.deploymentOptions = {
        s3Configuration: {
          uploadParams: [
            {
              filter: ['*.mp3', '*.jpg']
              params: {
                CacheControl: 'max-age=3600'
              }
            },
            {
              filter: ['*.html', '*.js'],
              params: {
                CacheControl: 'no-cache'
              }
            }
          ]
        }
      }

      assetSets = createAssetSets { s3Context, skillContext }

      expect(assetSets.length).to.equal(3)

      assetNames = []
      for asset in assetSets[0].assets
        assetNames.push asset.name
      expect(assetNames).to.have.all.members(['audio1.mp3', 'audio2.mp3', 'audio3.mp3', 'image1.jpg', 'image2.jpg'])
      expect(assetSets[0].params.CacheControl).to.equal('max-age=3600')

      assetNames = []
      for asset in assetSets[1].assets
        assetNames.push asset.name
      expect(assetNames).to.have.all.members(['index.html', 'error.html', 'main.js'])
      expect(assetSets[1].params.CacheControl).to.equal('no-cache')

      assetNames = []
      for asset in assetSets[2].assets
        assetNames.push asset.name
      expect(assetNames).to.have.all.members(['style.css'])
      expect(assetSets[2].params).to.equal(undefined)

    it 'should correctly identify nested assets', ->
      skillContext.deploymentOptions = {
        s3Configuration: {
          uploadParams: [
            {
              filter: ['*.html', '*.js'],
              params: {
                CacheControl: 'no-cache'
              }
            }
          ]
        }
      }

      s3Context.uploads = [ { name: 'html/test.js' } ]

      assetSets = createAssetSets { s3Context, skillContext }

      expect(assetSets.length).to.equal(1)
      expect(assetSets[0].assets).to.deep.equal([{ name: 'html/test.js' }])
      expect(assetSets[0].params.CacheControl).to.equal('no-cache')

    it 'should correctly apply default properties to non-filtered files wherever default properties are defined', ->
      skillContext.deploymentOptions = {
        s3Configuration: {
          uploadParams: [
            {
              filter: ['filteredBeforeDefault.js'],
              params: {
                CacheControl: 'before'
              }
            }
            {
              filter: ['*'],
              params: {
                CacheControl: 'default'
              }
            }
            {
              filter: ['filteredAfterDefault.js'],
              params: {
                CacheControl: 'after'
              }
            }
          ]
        }
      }

      s3Context.uploads = [
        { name: 'filteredBeforeDefault.js' },
        { name: 'unfiltered.js' },
        { name: 'filteredAfterDefault.js' }
      ]

      assetSets = createAssetSets { s3Context, skillContext }

      expect(assetSets.length).to.equal(3)
      expect(assetSets[0]).to.deep.equal(
        {
          assets: [{ name: 'filteredBeforeDefault.js' }],
          params: {
            CacheControl: 'before'
          }
        }
      )
      expect(assetSets[1]).to.deep.equal(
        {
          assets: [{ name: 'filteredAfterDefault.js' }],
          params: {
            CacheControl: 'after'
          }
        }
      )
      expect(assetSets[2]).to.deep.equal(
        {
          assets: [{ name: 'unfiltered.js' }],
          params: {
            CacheControl: 'default'
          }
        }
      )

  describe '#findAndRegisterFilesToUpload()', ->
    s3Context = {
      baseLocation: "dummyBase"
      assets: {}
    }
    languageInfo = {
      default: {
        assets: {
          files: ['subdir\\image.png']
          root: "dummyRoot"
        }
        convertedAssets: {
          files: []
          root: "dummyRoot"
        }
      }
      en: {
        assets: {
          files: ['otherSubdir\\something.png']
          root: "enDummyRoot"
        }
        convertedAssets: {
          files: []
          root: "dummyRoot"
        }
      }
    }
    it 'uploads asset subdirectory files in Windows', ->
      findAndRegisterFilesToUpload({s3Context, languageInfo})
      expect(Object.keys(s3Context.assets).length).to.equal(3)
      asset = s3Context.assets["dummyBase/default/subdir/image.png"]
      expect(asset).to.not.equal(undefined)
      expect(asset.name.includes('\\')).to.equal(true)
      expect(asset.sourceFilename.includes('\\')).to.equal(true)
      asset = s3Context.assets["dummyBase/en/otherSubdir/something.png"]
      expect(asset).to.not.equal(undefined)
      expect(asset.name.includes('\\')).to.equal(true)
      expect(asset.sourceFilename.includes('\\')).to.equal(true)


  describe '#uploadAssetSet()', ->
    skillContext = { S3: { upload: (params) -> { promise: () -> return } } }
    s3Context = {
      uploadIndex: 0,
      uploads: { length: 9 }
    }
    assetSets = [
      {
        params: {
          CacheControl: 'max-age=3600'
        },
        assets: [
          {
            name: 'audio1.mp3'
            key: 'audio1',
            sourceFilename: 'audio1.mp3',
            md5Brief: 'audio1md5'
          },
          {
            name: 'audio2.mp3'
            key: 'audio2',
            sourceFilename: 'audio2.mp3',
            md5Brief: 'audio2md5'
          },
          {
            name: 'audio3.mp3'
            key: 'audio3',
            sourceFilename: 'audio3.mp3',
            md5Brief: 'audio3md5'
          }
        ]
      },
      {
        params: {
          CacheControl: 'no-cache'
        },
        assets: [
          {
            name: 'style.css',
            key: 'style',
            sourceFilename: 'style.css',
            md5Brief: 'stylemd5'
          },
          {
            name: 'main.js',
            key: 'main',
            sourceFilename: 'main.js',
            md5Brief: 'mainmd5'
          },
          {
            name: 'index.html',
            key: 'index',
            sourceFilename: 'index.html',
            md5Brief: 'indexmd5'
          },
          {
            name: 'error.html',
            key: 'error',
            sourceFilename: 'error.html',
            md5Brief: 'errormd5'
          }
        ]
      },
      {
        params: {
          CacheControl: 'max-age=600'
        },
        assets: [
          {
            name: 'image1.jpg',
            key: 'image1',
            sourceFilename: 'image1.jpg',
            md5Brief: 'image1md5'
          },
          {
            name: 'image2.jpg',
            key: 'image2',
            sourceFilename: 'image2.jpg',
            md5Brief: 'image2md5'
          }
        ]
      }
    ]

    logger = { log: (message) -> return }
    fs = { createReadStream: (file) -> return }
    mime = { getType: (file) -> return }
    spy

    before ->
      spy = spy skillContext.S3, 'upload'

    it 'should not attempt to do any processing or uploading if asset set is undefined', ->
      for assetSet in assetSets
        uploadAssetSet { assetSet: undefined, s3Context, skillContext, logger, fs, mime }

      expect(spy.callCount).to.equal(0)
      expect(s3Context.uploadIndex).to.equal(0)

    it 'should upload all of the assets across all of the asset sets', ->
      for assetSet in assetSets
        uploadAssetSet { assetSet, s3Context, skillContext, logger, fs, mime }

      expect(spy.callCount).to.equal(s3Context.uploads.length)
      expect(s3Context.uploadIndex).to.equal(s3Context.uploads.length)
      spy.restore()
