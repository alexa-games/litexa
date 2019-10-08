/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const { validateDirectiveType } = require('./commonValidators');

const COLOR_REGEX = /^[A-F0-9]{6}$/;
const MAX_HANDLER_DURATION_MS = 300000; // 5 minutes

stopInputHandlerDirectiveValidator = function(validator) {
  const directive = validator.jsonObject;
  const requiredKeys = ['type', 'originatingRequestId'];
  validator.strictlyOnly(requiredKeys);

  validateDirectiveType({ validator, directive, expectedType: 'GameEngine.StopInputHandler' });
}

startInputHandlerDirectiveValidator = function(validator) {
  const directive = validator.jsonObject;
  const requiredKeys = ['type', 'timeout', 'recognizers', 'events'];
  const optionalKeys = ['proxies'];
  const validKeys = requiredKeys.concat(optionalKeys);

  validator.require(requiredKeys);
  validator.whiteList(validKeys);

  validateDirectiveType({ validator, directive, expectedType: 'GameEngine.StartInputHandler' });

  validator.integerBounds('timeout', 0, MAX_HANDLER_DURATION_MS);

  if (directive.proxies != null && !Array.isArray(directive.proxies)) {
    validator.fail('proxies', "should be an array");
  }

  validateAllRecognizers(validator, directive);
  validateAllEvents(validator, directive);
}

validateAllRecognizers = function(validator, directive) {
  const recognizers = directive.recognizers;
  if (recognizers == null) {
    return;
  }

  if (recognizers.constructor !== Object) {
    validator.fail('recognizers', 'should be an object');
  } else {
    validator.push('recognizers', function() {
      for (const [name, recognizer] of Object.entries(recognizers)) {
        validator.push(name, function() {
          validateRecognizer({ validator, directive, recognizer });
        });
      }
    });
  }
}

validateRecognizer = function({ validator, directive, recognizer }) {
  validator.oneOf('type', ['match', 'deviation', 'progress']);

  const validatorFunction = recognizerFunctions[`${recognizer.type}`];
  if (validatorFunction != null) {
    validatorFunction({ validator, directive, recognizer });
  }
}

recognizerFunctions = {
  'match': function({ validator, recognizer }) {
    const requiredKeys = ['type', 'pattern']
    const optionalKeys = ['actions', 'anchor', 'fuzzy', 'gadgetIds']
    const validKeys = requiredKeys.concat(optionalKeys);

    validator.require(requiredKeys);
    validator.whiteList(validKeys);

    if (recognizer.anchor != null) {
      validator.oneOf('anchor', ['start', 'end', 'anywhere']);
    }
    if (recognizer.fuzzy != null) {
      validator.boolean('fuzzy');
    }

    validateGadgetIds(validator, recognizer.gadgetIds);
    validateActions(validator, recognizer.actions);
    validateAllPatterns(validator, recognizer);
  },

  'deviation': function({ validator, directive, recognizer }) {
    validator.require(['type', 'recognizer']);

    validateRecognizerName({ validator, directive, recognizer: recognizer.recognizer });
  },

  'progress': function({ validator, directive, recognizer }) {
    validator.require(['type', 'recognizer', 'completion']);

    validateRecognizerName({ validator, directive, recognizer: recognizer.recognizer });

    if (recognizer.completion != null) {
      validator.integerBounds('completion', 0, 100);
    }
  }
}

validateRecognizerName = function({ validator, directive, recognizer }) {
  if (recognizer == null)
    return;

  if (typeof(recognizer) !== 'string')
    validator.fail(`recognizer`, 'should be a string');
  else if (directive.recognizers == null || !directive.recognizers.hasOwnProperty(recognizer))
    validator.fail('recognizer', 'recognizer not found in the recognizers object');
}

validateAllPatterns = function(validator, recognizer) {
  const patterns = recognizer.pattern;
  if (patterns == null)
    return;

  if (Array.isArray(patterns)) {
    for (let i = 0; i < patterns.length; ++i) {
      const pattern = patterns[i];
      validator.push('pattern', function() {
        validator.push(i, function() {
          validatePattern(validator, pattern);
        });
      });
    }
  } else {
    validator.fail('pattern', 'should be an array of patterns');
  }
}

validatePattern = function(validator, pattern) {
  const optionalKeys = ['gadgetIds', 'action', 'colors', 'repeat'];
  validator.whiteList(optionalKeys);

  if (pattern.action != null) {
    validator.oneOf("action", ['up', 'down']);
  }
  if (pattern.repeat != null) {
    validator.integerBounds('repeat', 1, 99999);
  }

  validateColors(validator, pattern.colors);
  validateGadgetIds(validator, pattern.gadgetIds);
}

validateColors = function(validator, colors) {
  if (colors == null)
    return;

  if (Array.isArray(colors)) {
    for (const [index, color] of Object.entries(colors)) {
      if (!COLOR_REGEX.exec(color))
        validator.fail(`colors[${index}]`, 'should be a color in the format FFFFFF');
    }
  } else {
    validator.fail('colors', 'should be an array of acceptable colors');
  }
}

validateGadgetIds = function(validator, gadgetIds) {
  if (gadgetIds == null)
    return;

  if (Array.isArray(gadgetIds)) {
    for (let i = 0; i < gadgetIds.length; ++i) {
      const gadgetId = gadgetIds[i];
      if (typeof(gadgetId) !== 'string') {
        validator.fail(`gadgetIds[${i}]`, 'should be a string');
      }
    }
  } else {
    validator.fail('gadgetIds', 'should be an array of gadgetId strings');
  }
}

validateActions = function(validator, actions) {
  if (actions == null)
    return;

  const validActions = ['up', 'down'];
  if (Array.isArray(actions)) {
    for (let i = 0; i < actions.length; ++i) {
      validator.oneOf(`actions[${i}]`, validActions);
    }
  } else {
    validator.fail('actions', "should be an array of actions to include, e.g. ['up', 'down']");
  }
}

validateAllEvents = function(validator, directive) {
  const events = directive.events;
  if (events == null)
    return

  if (events.constructor !== Object) {
    validator.fail('events', 'should be an object');
  } else {
    validator.push('events', function() {
      for (const [name, event] of Object.entries(events)) {
        validator.push(name, function() {
          validateEvent({ validator, directive, event });
        });
      }
    });
  }
}

validateEvent = function({ validator, directive, event }) {
  const requiredKeys = ['meets', 'shouldEndInputHandler'];
  const optionalKeys = ['fails', 'reports', 'maximumInvocations', 'triggerTimeMilliseconds'];
  const validKeys = requiredKeys.concat(optionalKeys);

  validator.require(requiredKeys);
  validator.whiteList(validKeys);

  validateEventRecognizers({ validator, directive, event });

  if (event.shouldEndInputHandler != null) {
    validator.boolean('shouldEndInputHandler');
  }

  validator.oneOf('reports', ['matches', 'history', 'nothing']);
  if (event.maximumInvocations != null) {
    validator.integerBounds('maximumInvocations', 1, 2048);
  }

  if (event.triggerTimeMilliseconds != null) {
    validator.integerBounds('triggerTimeMilliseconds', 0, MAX_HANDLER_DURATION_MS);

    if (event.maximumInvocations != null) {
      validator.fail("triggerTimeMilliseconds", "should not be present if `maximumInvocations` is also present");
    }
  }
}

validateEventRecognizers = function({ validator, directive, event }) {
  const eventTypesToCheck = ['meets', 'fails'];
  const builtInRecognizers = ['timed out'];

  for (const type of eventTypesToCheck) {
    const recognizers = event[`${type}`];
    if (recognizers == null)
      continue;

    if (Array.isArray(recognizers)) {
      recognizers.forEach(function(recognizer, index) {
        if ((directive.recognizers == null || !directive.recognizers.hasOwnProperty(recognizer))
            && !builtInRecognizers.includes(recognizer)) {
          validator.fail(`${type}[${index}]`, 'recognizer not found in the recognizers object');
        }
      });
    } else {
      validator.fail(`${type}`, 'should be an array of recognizer names');
    }
  }
}

module.exports = {
  startInputHandlerDirectiveValidator,
  stopInputHandlerDirectiveValidator
};
