/*
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved.
 * These materials are licensed as "Restricted Program Materials" under the Program Materials
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service.
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html.
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized
 * terms not defined in this file have the meanings given to them in the Agreement.
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
