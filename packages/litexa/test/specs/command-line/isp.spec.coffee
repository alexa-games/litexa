###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

{ expect } = require 'chai'
{ assert, match, stub } = require 'sinon'

Artifacts = require('../../../src/deployment/artifacts').Artifacts
isp = require '@src/command-line/isp'
smapi = require '@src/command-line/api/smapi'

describe 'ISP', ->
  isp.artifacts = undefined
  isp.skillId = undefined
  mockArtifactSummary = undefined
  mockProduct = undefined
  smapiStub = undefined

  beforeEach ->
    mockArtifactSummary = {}
    mockArtifacts = new Artifacts(null, {
      versions: [
        {}
      ]
    })
    mockArtifacts.setVariant('development')
    mockArtifacts.save 'monetization', {}

    isp.init({
      artifacts: mockArtifacts
      logger: { log: () -> undefined }
      root: '.'
      skillId: 'mockSkillId'
      stage: 'development'
    })

    mockProduct = {
      productId: 'mockProductId'
      referenceName: 'mockReferenceName'
      filePath: 'mockFilePath'
    }

    fakeSmapiCall = (args) -> Promise.resolve('{}')
    smapiStub = stub(isp.smapi, 'call').callsFake(fakeSmapiCall)

  afterEach ->
    smapiStub.restore()

  it 'successfully checks a list for a specific product', ->
    mockList = [
      {
        productId: 'otherId'
      }
    ]
    expect(isp.listContainsProduct(mockList, mockProduct)).to.be.false

    mockList.push({
      productId: 'mockProductId'
    })
    expect(isp.listContainsProduct(mockList, mockProduct)).to.be.true

  it 'provides correct CLI args for pulling a list of remote products', ->
    await isp.pullRemoteProductList(mockProduct, mockArtifactSummary)

    expect(smapiStub.callCount).to.equal(1)
    if smapi.version.major < 2
      assert.calledWithMatch(smapiStub, {
        command: 'list-isp-for-skill'
        params: {
          'skill-id': isp.skillId
          'stage': isp.stage
        }
      })
    else
      assert.calledWithMatch(smapiStub, {
        command: 'get-isp-list-for-skill-id'
        params: {
          'skill-id': isp.skillId
          'stage': isp.stage
        }
      })


  it 'provides correct CLI args for retrieving definition for a product', ->
    await isp.getProductDefinition(mockProduct)

    expect(smapiStub.callCount).to.equal(1)
    if smapi.version.major < 2
      assert.calledWithMatch(smapiStub, {
        command: 'get-isp'
        params: {
          'isp-id': mockProduct.productId
          'stage': isp.stage
        }
      })
    else
      assert.calledWithMatch(smapiStub, {
        command: 'get-isp-definition'
        params: {
          'product-id': mockProduct.productId
          'stage': isp.stage
        }
      })


  it 'provides correct CLI args for creating a remote product', ->
    isp.artifacts.save 'monetization', {
      mockReferenceName: {
        productId: 'mockProductId'
      }
    }

    await isp.createRemoteProduct(mockProduct, mockArtifactSummary)

    if smapi.version.major < 2
      expect(smapiStub.callCount).to.equal(2)
      assert.calledWithMatch(smapiStub.firstCall, {
        command: 'create-isp'
        params: {
          file: mockProduct.filePath
        }
      })
    else
      expect(smapiStub.callCount).to.equal(2)
      assert.calledWithMatch(smapiStub.firstCall, {
        command: 'create-isp-for-vendor'
        params: {
          'create-in-skill-product-request': "file:#{mockProduct.filePath}"
        }
      })


    if smapi.version.major < 2
      assert.calledWithMatch(smapiStub.secondCall, {
        command: 'associate-isp'
        params: {
          'isp-id': mockProduct.productId
          'skill-id': isp.skillId
        }
      })
    else
      assert.calledWithMatch(smapiStub.secondCall, {
        command: 'associate-isp-with-skill'
        params: {
          'product-id': mockProduct.productId
          'skill-id': isp.skillId
        }
      })

  it 'provides correct CLI args for updating a remote product', ->
    isp.artifacts.save 'monetization', {
      mockReferenceName: {
        productId: 'mockProductId'
      }
    }

    await isp.updateRemoteProduct(mockProduct, mockArtifactSummary)

    expect(smapiStub.callCount).to.equal(1)
    if smapi.version.major < 2
      assert.calledWithMatch(smapiStub, {
        command: 'update-isp'
        params: {
          'isp-id': mockProduct.productId
          file: mockProduct.filePath
          stage: isp.stage
        }
      })
    else
      assert.calledWithMatch(smapiStub, {
        command: 'update-isp-for-product'
        params: {
          'product-id': mockProduct.productId
          'in-skill-product': "file:#{mockProduct.filePath}"
          stage: isp.stage
        }
      })


    expect(mockArtifactSummary).to.deep.equal({
      "#{mockProduct.referenceName}": {
        productId: mockProduct.productId
        }
      })

  it 'provides correct CLI args for disassociating and deleting a remote product', ->
    await isp.deleteRemoteProduct(mockProduct)

    expect(smapiStub.callCount).to.equal(2)
    if smapi.version.major < 2
      assert.calledWithMatch(smapiStub.firstCall, {
        command: 'disassociate-isp'
        params: {
          'isp-id': mockProduct.productId
          'skill-id': isp.skillId
        }
      })
    else
      assert.calledWithMatch(smapiStub.firstCall, {
        command: 'disassociate-isp-with-skill'
        params: {
          'product-id': mockProduct.productId
          'skill-id': isp.skillId
        }
      })


    if smapi.version.major < 2
      assert.calledWithMatch(smapiStub.secondCall, {
        command: 'delete-isp'
        params: {
          'isp-id': mockProduct.productId
          stage: isp.stage
        }
      })
    else
      assert.calledWithMatch(smapiStub.secondCall, {
        command: 'delete-isp-for-product'
        params: {
          'product-id': mockProduct.productId
          stage: isp.stage
        }
      })



  it 'provides correct CLI args for associating a product', ->
    await isp.associateProduct(mockProduct)

    expect(smapiStub.callCount).to.equal(1)
    if smapi.version.major < 2
      assert.calledWithMatch(smapiStub, {
        command: 'associate-isp'
        params: {
          'isp-id': mockProduct.productId
          'skill-id': isp.skillId
        }
      })
    else
      assert.calledWithMatch(smapiStub, {
        command: 'associate-isp-with-skill'
        params: {
          'product-id': mockProduct.productId
          'skill-id': isp.skillId
        }
      })
