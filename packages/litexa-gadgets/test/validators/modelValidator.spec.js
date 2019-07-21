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

const { modelValidatorForGadgets } = require('../../src/validators/modelValidator');

require('coffeescript').register();
const { JSONValidator } = require('@litexa/core/src/parser/jsonValidator.coffee').lib;

describe('modelValidatorForGadgets', function() {
  const validator = new JSONValidator();
  const skill = {
    collectRequiredAPIs: function(obj) {
      obj['GAME_ENGINE'] = true;
    }
  }

  beforeEach(function() {
    validator.reset();
  });

  it('passes for a model that satisfies all gadget requirements', function() {
    validator.jsonObject = {
      languageModel: {
        intents: [
          { name: 'AMAZON.HelpIntent', samples: [] },
          { name: 'AMAZON.StopIntent', samples: [] }
        ]
      }
    }

    modelValidatorForGadgets({ validator, skill });
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([]);
  });

  it('fails with appropriate error for missing intents', function() {
    validator.jsonObject = {
      languageModel: {
        intents: []
      }
    }

    const expectedError = `When using the GAME_ENGINE interface, you must implement the following intents:
  ["AMAZON.HelpIntent","AMAZON.StopIntent"] -> add at least one 'when' statement to handle each missing intent.`

    modelValidatorForGadgets({ validator, skill });
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      expectedError
    ]);
  });
});
