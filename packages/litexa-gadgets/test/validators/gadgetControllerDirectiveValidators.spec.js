/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const { expect } = require('chai');

const {
  setLightDirectiveValidator
} = require('../../src/validators/gadgetControllerDirectiveValidators');

require('coffeescript').register();
const { JSONValidator } = require('@litexa/core/src/parser/jsonValidator.coffee').lib;

describe('gadgetControllerDirectiveValidators', function () {
  const validator = new JSONValidator();

  beforeEach(function () {
    validator.reset();
  });

  it('validates SetLight directive type', function () {
    validator.jsonObject = {
      type: 'GadgetController.SetLight',
      version: 1,
      targetGadgets: ['gadgetId1', 'gadgetId2'],
      parameters: {
        triggerEvent: 'none',
        triggerEventTimeMs: 0,
        animations: [
          {
            repeat: 1,
            targetLights: ['1'],
            sequence: [
              {
                durationMs: 10000,
                blend: false,
                color: '0000FF'
              }
            ]
          }
        ]
      }
    }

    setLightDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([]);

    validator.reset()
    validator.jsonObject.type = 'invalidType'

    setLightDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".type: 'invalidType'; should be 'GadgetController.SetLight'"
    ]);
  });

  it('validates SetLight directive keys', function () {
    validator.jsonObject = {
      type: 'GadgetController.SetLight'
    }

    setLightDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".version: undefined; missing required parameter",
      ".parameters: undefined; missing required parameter"
    ]);
  });

  it('validates SetLight directive data types', function () {
    validator.jsonObject = {
      type: 'GadgetController.SetLight',
      version: 'notANumber',
      targetGadgets: 'notAnArray',
      parameters: {
        triggerEvent: {},
        triggerEventTimeMs: 'notANumber',
        animations: [
          {
            repeat: 'notANumber',
            targetLights: 'notAnArray',
            sequence: [
              {
                durationMs: 'notANumber',
                blend: 'notABoolean',
                color: {}
              }
            ]
          }
        ]
      }
    }

    setLightDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".version: 'notANumber'; should be exactly the number 1",
      ".targetGadgets: 'notAnArray'; should be an array",
      ".parameters.triggerEvent: {}; should only be one of [\"buttonDown\",\"buttonUp\",\"none\"]",
      ".parameters.triggerEventTimeMs: 'notANumber'; should be an integer between 0 and 65535, inclusive",
      ".parameters.animations[0].repeat: 'notANumber'; should be an integer between 0 and 255, inclusive",
      ".parameters.animations[0].targetLights: 'notAnArray'; should be an array",
      ".parameters.animations[0].sequence[0].color: {}; must be a hex color string in the form FFFFFF",
      ".parameters.animations[0].sequence[0].durationMs: 'notANumber'; should be an integer between 1 and 65535, inclusive",
      ".parameters.animations[0].sequence[0].blend: 'notABoolean'; should be true or false"
    ]);
  });

  it('validates SetLight directive data values', function () {
    validator.jsonObject = {
      type: 'GadgetController.SetLight',
      version: 2,
      targetGadgets: ['gadgetId1', 2],
      parameters: {
        triggerEvent: 'invalidTriggerEvent',
        triggerEventTimeMs: 65536,
        animations: [
          {
            repeat: 256,
            targetLights: ['2'],
            sequence: [
              {
                durationMs: 65536,
                color: 'invalidColor'
              }
            ]
          }
        ]
      }
    }

    setLightDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".version: 2; should be exactly the number 1",
      ".targetGadgets[1]: 2; should be a string",
      ".parameters.triggerEvent: 'invalidTriggerEvent'; should only be one of [\"buttonDown\",\"buttonUp\",\"none\"]",
      ".parameters.triggerEventTimeMs: 65536; should be between 0 and 65535, inclusive",
      ".parameters.animations[0].repeat: 256; should be between 0 and 255, inclusive",
      ".parameters.animations[0].targetLights[0]: '2'; should be exactly '1', to indicate the single light",
      ".parameters.animations[0].sequence[0].blend: undefined; missing required parameter",
      ".parameters.animations[0].sequence[0].color: 'invalidColor'; must be a hex color string in the form FFFFFF",
      ".parameters.animations[0].sequence[0].durationMs: 65536; should be between 1 and 65535, inclusive"
    ]);
  });

  it('validates missing and invalid parameters', function () {
    validator.jsonObject = {
      type: 'GadgetController.SetLight',
      version: 1,
      targetGadgets: ['gadgetId1']
    }

    setLightDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".parameters: undefined; missing required parameter"
    ]);

    validator.jsonObject.parameters = {}

    validator.reset();
    setLightDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".parameters.triggerEvent: undefined; missing required parameter",
      ".parameters.triggerEventTimeMs: undefined; missing required parameter",
      ".parameters.animations: undefined; missing required parameter"
    ]);

    validator.jsonObject.parameters = {
      triggerEvent: 'none',
      triggerEventTimeMs: 0,
      animations: {}
    }

    validator.reset();
    setLightDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".parameters.animations: {}; should be an array of animations"
    ]);

    const emptyArray = new Array(39);

    validator.jsonObject.parameters = {
      triggerEvent: 'none',
      triggerEventTimeMs: 0,
      animations: [
        {
          repeat: 1,
          targetLights: ['1', '2'],
          sequence: {}
        },
        {
          repeat: 1,
          targetLights: ['1'],
          sequence: new Array(39)
        },
        {
        }
      ]
    }

    validator.reset();
    setLightDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".parameters.animations[0].targetLights: [\"1\",\"2\"]; should only have a single member, since Echo Buttons only have a single light",
      ".parameters.animations[0].sequence: {}; should be an array",
      `.parameters.animations[1].sequence: ${JSON.stringify(emptyArray)}; maximum entries supported in animation sequence is 38, found 39`,
      ".parameters.animations[2].repeat: undefined; missing required parameter",
      ".parameters.animations[2].targetLights: undefined; missing required parameter",
      ".parameters.animations[2].sequence: undefined; missing required parameter"
    ]);
  });
});
