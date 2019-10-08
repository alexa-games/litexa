/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

manifestValidatorForGadgets = function({ validator, skill }) {
  const manifest = validator.jsonObject;
  const requiredAPIs = {};
  skill.collectRequiredAPIs(requiredAPIs);

  if (requiredAPIs['GAME_ENGINE'] === true) {
    validator.require('manifest');
    if (manifest.manifest != null) {
      validator.push('manifest', function() {
        validatePublishingInformation(validator, manifest.manifest);
      });
    }
  }
}

validatePublishingInformation = function(validator, manifest) {
  validator.require('publishingInformation');
  if (manifest.publishingInformation != null) {
    validator.push('publishingInformation', function() {
      validateGadgetSupport(validator, manifest.publishingInformation);
    });
  } else {
    validator.errors.push(getGadgetErrorMessage());
  }
}

validateGadgetSupport = function(validator, publishingInformation) {
  validator.require('gadgetSupport');
  if (publishingInformation.gadgetSupport != null) {
    validator.push('gadgetSupport', function() {
      validateGadgetSpecs(validator, publishingInformation.gadgetSupport);
    });
  } else {
    validator.errors.push(getGadgetErrorMessage());
  }
}

getGadgetErrorMessage = function() {
  const sampleJSON = {
    publishingInformation: {
      gadgetSupport: {
        requirement: 'REQUIRED',
        numPlayersMin: 2,
        numPlayersMax: 4,
        minGadgetButtons: 2,
        maxGadgetButtons: 4,
      }
    }
  }

  const err = [
    'Using the GAME_ENGINE interface requires the following manifest information:',
    `${JSON.stringify(sampleJSON, null, 2)}`,
    'Please see this URL for further details, and update your skill config file:',
    'https://developer.amazon.com/docs/gadget-skills/specify-echo-button-skill-details.html#manifest-fields'
  ].join('\n').replace(/\n/g, '\n  '); // indent message with 2 spaces

  return err;
}

validateGadgetSpecs = function(validator, gadgetSpecs) {
  const requiredKeys = ['requirement', 'numPlayersMin', 'numPlayersMax', 'minGadgetButtons', 'maxGadgetButtons'];
  validator.require(requiredKeys);

  if (gadgetSpecs.requirement != null) {
    const validSettings = ['REQUIRED', 'OPTIONAL'];
    validator.oneOf('requirement', validSettings);
  }

  if (gadgetSpecs.numPlayersMin != null) {
    validator.integerBounds('numPlayersMin', 1, 4);
  }

  if (gadgetSpecs.numPlayersMax != null) {
    validator.integerBounds('numPlayersMax', 1, 4);
  }

  if (gadgetSpecs.minGadgetButtons != null) {
    validator.integerBounds('minGadgetButtons', 1, 4);
  }

  if (gadgetSpecs.maxGadgetButtons != null) {
    validator.integerBounds('maxGadgetButtons', 1, 4);
  }
}

module.exports = {
  manifestValidatorForGadgets
}
