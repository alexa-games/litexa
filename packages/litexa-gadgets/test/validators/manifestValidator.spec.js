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

const { manifestValidatorForGadgets } = require('../../src/validators/manifestValidator');

require('coffeescript').register();
const { JSONValidator } = require('@litexa/core/src/parser/jsonValidator.coffee').lib;

describe('manifestValidatorForGadgets', function() {
  const validator = new JSONValidator();
  const skill = {
    collectRequiredAPIs: function(obj) {
      obj['GAME_ENGINE'] = true;
    }
  }

  beforeEach(function() {
    validator.reset();
  });

  it('passes for a manifest that satisfies all gadget requirements', function() {
    validator.jsonObject = {
      manifest: {
        publishingInformation: {
          gadgetSupport: {
            requirement: 'REQUIRED',
            numPlayersMin: 2,
            numPlayersMax: 4,
            minGadgetButtons: 2,
            maxGadgetButtons: 4
          }
        }
      }
    }

    manifestValidatorForGadgets({ validator, skill });
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([]);
  });

  it('fails with appropriate error on missing publishingInformation', function() {
    validator.jsonObject = {
      manifest: {
      }
    }

    const expectedError = `Using the GAME_ENGINE interface requires the following manifest information:
  {
    "publishingInformation": {
      "gadgetSupport": {
        "requirement": "REQUIRED",
        "numPlayersMin": 2,
        "numPlayersMax": 4,
        "minGadgetButtons": 2,
        "maxGadgetButtons": 4
      }
    }
  }
  Please see this URL for further details, and update your skill config file:
  https://developer.amazon.com/docs/gadget-skills/specify-echo-button-skill-details.html#manifest-fields`

    manifestValidatorForGadgets({ validator, skill });
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".manifest.publishingInformation: undefined; missing required parameter",
      expectedError
    ]);
  });

  it('fails with appropriate error on missing gadgetSupport', function() {
    validator.jsonObject = {
      manifest: {
        publishingInformation: {
        }
      }
    }

    const expectedError = `Using the GAME_ENGINE interface requires the following manifest information:
  {
    "publishingInformation": {
      "gadgetSupport": {
        "requirement": "REQUIRED",
        "numPlayersMin": 2,
        "numPlayersMax": 4,
        "minGadgetButtons": 2,
        "maxGadgetButtons": 4
      }
    }
  }
  Please see this URL for further details, and update your skill config file:
  https://developer.amazon.com/docs/gadget-skills/specify-echo-button-skill-details.html#manifest-fields`

    manifestValidatorForGadgets({ validator, skill });
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".manifest.publishingInformation.gadgetSupport: undefined; missing required parameter",
      expectedError
    ]);
  });

  it('fails with appropriate error messages for invalid or missing gadgetSupport settings', function() {
    validator.jsonObject = {
      manifest: {
        publishingInformation: {
          gadgetSupport: {
            requirement: 'invalidRequirement',
            numPlayersMin: 0,
            numPlayersMax: 5
          }
        }
      }
    }

    manifestValidatorForGadgets({ validator, skill });
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".manifest.publishingInformation.gadgetSupport.minGadgetButtons: undefined; missing required parameter",
      ".manifest.publishingInformation.gadgetSupport.maxGadgetButtons: undefined; missing required parameter",
      ".manifest.publishingInformation.gadgetSupport.requirement: 'invalidRequirement'; should only be one of [\"REQUIRED\",\"OPTIONAL\"]",
      ".manifest.publishingInformation.gadgetSupport.numPlayersMin: 0; should be between 1 and 4, inclusive",
      ".manifest.publishingInformation.gadgetSupport.numPlayersMax: 5; should be between 1 and 4, inclusive"
    ]);
  });
});
