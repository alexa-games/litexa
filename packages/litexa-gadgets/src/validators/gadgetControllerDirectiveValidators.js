/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const { validateDirectiveType } = require('./commonValidators');

const COLOR_REGEX = /^[A-F0-9]{6}$/;

setLightDirectiveValidator = function(validator) {
  const directive = validator.jsonObject;
  const requiredKeys = ['type', 'version', 'parameters'];
  const optionalKeys = ['targetGadgets'];
  const validKeys = requiredKeys.concat(optionalKeys);

  validator.require(requiredKeys);
  validator.allowOnly(validKeys);

  validateDirectiveType({ validator, directive, expectedType: 'GadgetController.SetLight' })

  if (directive.version != null && directive.version !== 1) {
    validator.fail('version', 'should be exactly the number 1');
  }

  validateTargetGadgets(validator, directive);

  if (directive.parameters != null) {
    validator.push('parameters', function() {
      validateSetLightParameters(validator, directive.parameters);
    });
  }
}

validateTargetGadgets = function(validator, directive) {
  const targetGadgets = directive.targetGadgets;
  if (targetGadgets == null)
    return;

  if (Array.isArray(targetGadgets)) {
    validator.push('targetGadgets', function() {
      for (let i = 0; i < targetGadgets.length; ++i) {
        if (typeof(targetGadgets[i]) !== 'string')
          validator.fail(i, 'should be a string');
      }
    });
  } else {
    validator.fail('targetGadgets', 'should be an array');
  }
}

validateSetLightParameters = function(validator, parameters) {
  const requiredKeys = ['triggerEvent', 'triggerEventTimeMs', 'animations'];
  validator.require(requiredKeys);

  if (parameters.triggerEvent != null) {
    const validTriggerEvents = ['buttonDown', 'buttonUp', 'none'];
    validator.oneOf('triggerEvent', validTriggerEvents);
  }

  if (parameters.triggerEventTimeMs != null) {
    validator.integerBounds('triggerEventTimeMs', 0, 65535);
  }

  validateAllAnimations(validator, parameters);
}

validateAllAnimations = function(validator, parameters) {
  const animations = parameters.animations;
  if (animations == null)
    return;

  if (Array.isArray(animations)) {
    for (let i = 0; i < animations.length; ++i) {
      const animation = animations[i];
      validator.push('animations', function() {
        validator.push(i, function() {
          validateAnimation(validator, animation);
        });
      });
    }
  } else {
    validator.fail('animations', 'should be an array of animations');
  }
}

validateAnimation = function(validator, animation) {
  const requiredKeys = ['repeat', 'targetLights', 'sequence'];
  validator.require(requiredKeys);

  if (animation.repeat != null) {
    validator.integerBounds('repeat', 0, 255);
  }

  validateAnimationTargetLights(validator, animation);
  validateAnimationSequence(validator, animation);
}

validateAnimationTargetLights = function(validator, animation) {
  const targetLights = animation.targetLights;
  if (targetLights == null)
    return;

  if (Array.isArray(targetLights)) {
    for (let i = 0; i < targetLights.length; ++i) {
      if (i > 0) {
        validator.fail('targetLights', 'should only have a single member, since Echo Buttons only have a single light');
      } else if (targetLights[i] != '1') {
        validator.fail(`targetLights[${i}]`, "should be exactly '1', to indicate the single light");
      }
    }
  } else {
    validator.fail('targetLights', 'should be an array');
  }
}

validateAnimationSequence = function(validator, animation) {
  const sequence = animation.sequence;
  if (sequence == null)
    return;

  if (Array.isArray(sequence)) {
    if (sequence.length > 38) {
      validator.fail('sequence', `maximum entries supported in animation sequence is 38, found ${sequence.length}`);
    } else {
      validator.push('sequence', function() {
        for (let i = 0; i < sequence.length; ++i) {
          validator.push(i, function() {
            validateAnimationSequenceStep(validator, sequence[i]);
          });
        }
      });
    }
  } else {
    validator.fail('sequence', 'should be an array');
  }
}

validateAnimationSequenceStep = function(validator, step) {
  const requiredKeys = ['color', 'durationMs', 'blend'];
  validator.require(requiredKeys);

  if (step.color != null && !COLOR_REGEX.exec(step.color)) {
    validator.fail('color', 'must be a hex color string in the form FFFFFF');
  }

  if (step.durationMs != null) {
    validator.integerBounds('durationMs', 1, 65535);
  }

  if (step.blend != null) {
    validator.boolean('blend');
  }
}

module.exports = {
  setLightDirectiveValidator
}
