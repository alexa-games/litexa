/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const { expect } = require('chai');

const {
  sendDirectiveValidator,
  startEventHandlerDirectiveValidator,
  stopEventHandlerDirectiveValidator
} = require('../../src/validators/customInterfaceDirectiveValidators');

require('coffeescript').register();
const { JSONValidator } = require('@litexa/core/src/parser/jsonValidator.coffee').lib;

describe('customInterfaceDirectiveValidators', function () {
  const validator = new JSONValidator();

  beforeEach(function () {
    validator.reset();
  });

  it('validates CustomInterfaceController.SendDirective directive type', function () {
    validator.jsonObject = {
      type: 'CustomInterfaceController.SendDirective'
    }

    sendDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".header: undefined; missing required parameter",
      ".endpoint: undefined; missing required parameter",
      ".payload: undefined; missing required parameter"
    ]);
  });

  it('validates CustomInterfaceController.StartEventHandler directive type', function () {
    validator.jsonObject = {
      type: 'CustomInterfaceController.StartEventHandler'
    }

    startEventHandlerDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".token: undefined; missing required parameter",
      ".eventFilter: undefined; missing required parameter",
      ".expiration: undefined; missing required parameter"
    ]);
  });

  it('validates CustomInterfaceController.StopEventHandler directive type', function () {
    validator.jsonObject = {
      type: 'CustomInterfaceController.StopEventHandler'
    }

    stopEventHandlerDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".token: undefined; missing required parameter"
    ]);
  });
});
