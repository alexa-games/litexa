
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


{ assert, expect } = require('chai')
{ fake, spy } = require('sinon')

{ validateCoreVersion } = require('../../../../src/command-line/deploy/validators')

describe 'Version validator', ->
  fakeInquirer = undefined
  promptSpy = undefined

  beforeEach ->
    fakeInquirer = {
      prompt: (args) -> fake.returns(Promise.resolve({ proceed: true }))
    }
    promptSpy = spy(fakeInquirer, 'prompt')

  it 'detects mismatching major version', ->
    # cur > prev
    validateCoreVersion {
      curCoreVersion: '0.2.0'
      prevCoreVersion: '0.1.0'
      inputHandler: fakeInquirer
    }

    expect(promptSpy.firstCall.args[0]).to.have.property(
      'message',
      "WARNING: This project was last deployed with version 0.1.0 of @litexa/core. A
        different minor version 0.2.0 is currently installed. Are you sure you want to proceed?"
    )

    # prev > cur
    validateCoreVersion {
      curCoreVersion: '0.1.0'
      prevCoreVersion: '0.2.0'
      inputHandler: fakeInquirer
    }

    expect(promptSpy.secondCall.args[0]).to.have.property(
      'message',
      "WARNING: This project was last deployed with version 0.2.0 of @litexa/core. A
        different minor version 0.1.0 is currently installed. Are you sure you want to proceed?"
    )

  it 'detects mismatching minor version', ->
    # cur > prev
    validateCoreVersion {
      curCoreVersion: '1.0.0'
      prevCoreVersion: '0.0.0'
      inputHandler: fakeInquirer
    }

    expect(promptSpy.firstCall.args[0]).to.have.property(
      'message',
      "WARNING: This project was last deployed with version 0.0.0 of @litexa/core. A
        different major version 1.0.0 is currently installed. Are you sure you want to proceed?"
    )

    # prev > cur
    validateCoreVersion {
      curCoreVersion: '0.1.0'
      prevCoreVersion: '1.0.0'
      inputHandler: fakeInquirer
    }

    expect(promptSpy.secondCall.args[0]).to.have.property(
      'message',
      "WARNING: This project was last deployed with version 1.0.0 of @litexa/core. A
        different major version 0.1.0 is currently installed. Are you sure you want to proceed?"
    )

  it 'ignores mismatching revision version', ->
    validateCoreVersion {
      curCoreVersion: '0.0.1'
      prevCoreVersion: '0.0.2'
      inputHandler: fakeInquirer
    }

    expect(promptSpy.callCount).to.equal(0)
