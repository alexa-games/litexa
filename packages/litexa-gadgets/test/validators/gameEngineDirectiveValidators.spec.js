/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const { expect } = require('chai');

const {
  startInputHandlerDirectiveValidator,
  stopInputHandlerDirectiveValidator
} = require('../../src/validators/gameEngineDirectiveValidators');

require('coffeescript').register();
const { JSONValidator } = require('@litexa/core/src/parser/jsonValidator.coffee').lib;

describe('gameEngineDirectiveValidators', function() {
  const validator = new JSONValidator();

  beforeEach(function() {
    validator.reset();
  });

  it('validates StopInputHandler directive type', function() {
    validator.jsonObject = {
      type: 'GameEngine.StopInputHandler',
      originatingRequestId: 'fakeId'
    };

    stopInputHandlerDirectiveValidator(validator);
    expect(validator.errors).to.deep.equal([]);

    validator.jsonObject = {
      type: 'GameEngine.StartInputHandler',
      originatingRequestId: 'fakeId'
    }

    stopInputHandlerDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".type: 'GameEngine.StartInputHandler'; should be 'GameEngine.StopInputHandler'"
    ]);
  });

  it('validates StopInputHandler directive keys', function() {
    validator.jsonObject = {};

    stopInputHandlerDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".type: undefined; missing required parameter",
      ".originatingRequestId: undefined; missing required parameter"
    ]);
  });

  it('validates StartInputHandler directive type', function() {
    validator.jsonObject = {
      type: 'GameEngine.StartInputHandler',
      timeout: 5000,
      proxies: [],
      recognizers: {},
      events: {}
    };

    startInputHandlerDirectiveValidator(validator);
    expect(validator.errors).to.deep.equal([]);

    validator.jsonObject = {
      type: 'GameEngine.StopInputHandler',
      timeout: 5000,
      proxies: [],
      recognizers: {},
      events: {}
    }

    startInputHandlerDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".type: 'GameEngine.StopInputHandler'; should be 'GameEngine.StartInputHandler'"
    ]);
  });


  it('validates StartInputHandler directive keys', function() {
    validator.jsonObject = {
      type: 'GameEngine.StartInputHandler',
      timeout: 300000,
      proxies: [],
      recognizers: {},
      events: {}
    };

    startInputHandlerDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([]);

    validator.jsonObject = {
      type: 'GameEngine.StartInputHandler',
      timeout: 300001,
      proxies: {},
      recognizers: 'notAnObject',
      events: []
    };
    validator.reset();

    startInputHandlerDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".timeout: 300001; should be between 0 and 300000, inclusive",
      ".proxies: {}; should be an array",
      ".recognizers: 'notAnObject'; should be an object",
      ".events: []; should be an object"
    ]);

    validator.jsonObject = {
      type: 'GameEngine.StartInputHandler',
      timeout: 300000,
      proxies: [],
      recognizers: {}
    };
    validator.reset();

    startInputHandlerDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".events: undefined; missing required parameter"
    ]);

    validator.jsonObject = {
      type: 'GameEngine.StartInputHandler',
      timeout: 300000,
      proxies: [],
      events: {}
    };
    validator.reset();

    startInputHandlerDirectiveValidator(validator);
    validator.errors = validator.errors.map(err => err.toString());
    expect(validator.errors).to.deep.equal([
      ".recognizers: undefined; missing required parameter"
    ]);
  });

  describe('validates StartInputHandler recognizers', function() {
    it('passes valid recognizers', function() {
      validator.jsonObject = {
        type: 'GameEngine.StartInputHandler',
        timeout: 0,
        recognizers: {
          button_down_recognizer: {
            type: 'match',
            fuzzy: false,
            actions: ['up'],
            anchor: 'end',
            pattern: [
              {
                action: 'down',
                repeat: 1,
                colors: ['FFFFFF'],
                gadgetIds: ['gadgetId']
              }
            ]
          },
          button_down_deviaton_recognizer: {
            type: 'deviation',
            recognizer: 'button_down_recognizer'
          },
          button_progress_recognizer: {
            type: 'progress',
            recognizer: 'button_down_recognizer',
            completion: 50
          }
        },
        events: {}
      };

      startInputHandlerDirectiveValidator(validator);
      validator.errors = validator.errors.map(err => err.toString());
      expect(validator.errors).to.deep.equal([]);
    });

    it('catches invalid recognizer type', function() {
      validator.jsonObject = {
        type: 'GameEngine.StartInputHandler',
        timeout: 0,
        recognizers: {
          aRecognizer: {
            type: 'invalidType'
          }
        },
        events: {}
      };

      startInputHandlerDirectiveValidator(validator);
      validator.errors = validator.errors.map(err => err.toString());
      expect(validator.errors).to.deep.equal([
        ".recognizers.aRecognizer.type: 'invalidType'; should only be one of [\"match\",\"deviation\",\"progress\"]"
      ]);
    });

    it('in a match recognizer, catches missing and invalid data types', function() {
      validator.jsonObject = {
        type: 'GameEngine.StartInputHandler',
        timeout: 0,
        recognizers: {
          invalidDataTypes: {
            type: 'match',
            actions: 'notAnArray',
            fuzzy: 'notABoolean',
            anchor: {},
            pattern: [
              {
                action: [],
                repeat: 'notANumber',
                colors: 'notAnArray',
                gadgetIds: 'notAnArray'
              }
            ],
            invalidKey: undefined
          },
          missingPattern: {
            type: 'match'
          },
          objectPattern: {
            type: 'match',
            pattern: {}
          },
          missingColors: {
            type: 'match',
            pattern: [
              {}
            ]
          }
        },
        events: {

        }
      };

      startInputHandlerDirectiveValidator(validator);
      validator.errors = validator.errors.map(err => err.toString());
      expect(validator.errors).to.deep.equal([
        ".recognizers.invalidDataTypes.invalidKey: undefined; unsupported parameter",
        ".recognizers.invalidDataTypes.anchor: {}; should only be one of [\"start\",\"end\",\"anywhere\"]",
        ".recognizers.invalidDataTypes.fuzzy: 'notABoolean'; should be true or false",
        ".recognizers.invalidDataTypes.actions: 'notAnArray'; should be an array of actions to include, e.g. ['up', 'down']",
        ".recognizers.invalidDataTypes.pattern[0].action: []; should only be one of [\"up\",\"down\"]",
        ".recognizers.invalidDataTypes.pattern[0].repeat: 'notANumber'; should be an integer between 1 and 99999, inclusive",
        ".recognizers.invalidDataTypes.pattern[0].colors: 'notAnArray'; should be an array of acceptable colors",
        ".recognizers.invalidDataTypes.pattern[0].gadgetIds: 'notAnArray'; should be an array of gadgetId strings",
        ".recognizers.missingPattern.pattern: undefined; missing required parameter",
        ".recognizers.objectPattern.pattern: {}; should be an array of patterns"
      ]);
    });

    it('in a match recognizer, catches invalid data values', function() {
      validator.jsonObject = {
        type: 'GameEngine.StartInputHandler',
        timeout: 0,
        recognizers: {
          rec: {
            type: 'match',
            fuzzy: true,
            actions: ['invalidAction'],
            anchor: 'invalidAnchor',
            pattern: [
              {
                action: 'invalidAction',
                repeat: 0,
                colors: ['invalidColor'],
                gadgetIds: [['invalidGadgetId']]
              }
            ]
          }
        },
        events: {}
      };

      startInputHandlerDirectiveValidator(validator);
      validator.errors = validator.errors.map(err => err.toString());
      expect(validator.errors).to.deep.equal([
        ".recognizers.rec.anchor: 'invalidAnchor'; should only be one of [\"start\",\"end\",\"anywhere\"]",
        ".recognizers.rec.actions[0]: 'invalidAction'; should only be one of [\"up\",\"down\"]",
        ".recognizers.rec.pattern[0].action: 'invalidAction'; should only be one of [\"up\",\"down\"]",
        ".recognizers.rec.pattern[0].repeat: 0; should be between 1 and 99999, inclusive",
        ".recognizers.rec.pattern[0].colors[0]: 'invalidColor'; should be a color in the format FFFFFF",
        ".recognizers.rec.pattern[0].gadgetIds[0]: [\"invalidGadgetId\"]; should be a string"
      ]);
    });

    it('in a deviation recognizer, catches missing and invalid recognizer', function() {
      validator.jsonObject = {
        type: 'GameEngine.StartInputHandler',
        timeout: 0,
        recognizers: {
          rec_1: {
            type: 'deviation'
          },
          rec_2: {
            type: 'deviation',
            recognizer: 'invalidRecognizer'
          }
        },
        events: {}
      };

      startInputHandlerDirectiveValidator(validator);
      validator.errors = validator.errors.map(err => err.toString());
      expect(validator.errors).to.deep.equal([
        ".recognizers.rec_1.recognizer: undefined; missing required parameter",
        ".recognizers.rec_2.recognizer: 'invalidRecognizer'; recognizer not found in the recognizers object"
      ]);
    });

    it('in a progress recognizer, catches missing and invalid data values', function() {
      validator.jsonObject = {
        type: 'GameEngine.StartInputHandler',
        timeout: 0,
        recognizers: {
          rec_1: {
            type: 'progress'
          },
          rec_2: {
            type: 'progress',
            recognizer: 'invalidRecognizer',
            completion: 101
          },
          rec_3: {
            type: 'progress',
            recognizer: {},
            completion: 'notANumber'
          }
        },
        events: {}
      };

      startInputHandlerDirectiveValidator(validator);
      validator.errors = validator.errors.map(err => err.toString());
      expect(validator.errors).to.deep.equal([
        ".recognizers.rec_1.recognizer: undefined; missing required parameter",
        ".recognizers.rec_1.completion: undefined; missing required parameter",
        ".recognizers.rec_2.recognizer: 'invalidRecognizer'; recognizer not found in the recognizers object",
        ".recognizers.rec_2.completion: 101; should be between 0 and 100, inclusive",
        ".recognizers.rec_3.recognizer: {}; should be a string",
        ".recognizers.rec_3.completion: 'notANumber'; should be an integer between 0 and 100, inclusive"
      ]);
    });
  });

  describe('validates StartInputHandler events', function() {
    it('passes valid events', function() {
      validator.jsonObject = {
        type: 'GameEngine.StartInputHandler',
        timeout: 0,
        recognizers: {
          rec_1: {
            type: 'match',
            fuzzy: false,
            actions: ['up'],
            anchor: 'end',
            pattern: [
              {
                action: 'down',
                repeat: 1,
                colors: ['FFFFFF'],
                gadgetIds: ['gadgetId']
              }
            ]
          },
          rec_2: {
            type: 'progress',
            recognizer: 'rec_1',
            completion: 100
          }
        },
        events: {
          myEventName: {
            meets: [ 'rec_1', 'timed out' ],
            fails: [ 'timed out', 'rec_2' ],
            reports: 'history',
            shouldEndInputHandler: true,
            maximumInvocations: 1
          }
        }
      };

      startInputHandlerDirectiveValidator(validator);
      validator.errors = validator.errors.map(err => err.toString());
      expect(validator.errors).to.deep.equal([]);
    });

    it('catches invalid event data types', function() {
      validator.jsonObject = {
        type: 'GameEngine.StartInputHandler',
        timeout: 0,
        recognizers: {
          rec_1: {
            type: 'match',
            fuzzy: false,
            actions: ['up'],
            anchor: 'end',
            pattern: [
              {
                action: 'down',
                repeat: 1,
                colors: ['FFFFFF'],
                gadgetIds: ['gadgetId']
              }
            ]
          },
          rec_2: {
            type: 'progress',
            recognizer: 'rec_1',
            completion: 100
          }
        },
        events: {
          myEventName_1: {
            meets: {},
            fails: 'notAnArray',
            reports: 0,
            shouldEndInputHandler: 'notABoolean',
            triggerTimeMilliseconds: 1000
          },
          myEventName_2: {
            reports: 'matches',
            shouldEndInputHandler: true,
            triggerTimeMilliseconds: 1000
          }
        }
      };

      startInputHandlerDirectiveValidator(validator);
      validator.errors = validator.errors.map(err => err.toString());
      expect(validator.errors).to.deep.equal([
        ".events.myEventName_1.meets: {}; should be an array of recognizer names",
        ".events.myEventName_1.fails: 'notAnArray'; should be an array of recognizer names",
        ".events.myEventName_1.shouldEndInputHandler: 'notABoolean'; should be true or false",
        ".events.myEventName_1.reports: 0; should only be one of [\"matches\",\"history\",\"nothing\"]",
        ".events.myEventName_2.meets: undefined; missing required parameter"
      ]);
    });

    it('catches invalid event data values', function() {
      validator.jsonObject = {
        type: 'GameEngine.StartInputHandler',
        timeout: 0,
        recognizers: {
        },
        events: {
          myEventName: {
            meets: ['rec_1'],
            fails: ['rec_2'],
            reports: 'invalidReport',
            maximumInvocations: 2049,
            triggerTimeMilliseconds: 300001
          }
        }
      };

      startInputHandlerDirectiveValidator(validator);
      validator.errors = validator.errors.map(err => err.toString());
      expect(validator.errors).to.deep.equal([
        ".events.myEventName.shouldEndInputHandler: undefined; missing required parameter",
        ".events.myEventName.meets[0]: 'rec_1'; recognizer not found in the recognizers object",
        ".events.myEventName.fails[0]: 'rec_2'; recognizer not found in the recognizers object",
        ".events.myEventName.reports: 'invalidReport'; should only be one of [\"matches\",\"history\",\"nothing\"]",
        ".events.myEventName.maximumInvocations: 2049; should be between 1 and 2048, inclusive",
        ".events.myEventName.triggerTimeMilliseconds: 300001; should be between 0 and 300000, inclusive",
        ".events.myEventName.triggerTimeMilliseconds: 300001; should not be present if `maximumInvocations` is also present"
      ]);
    });
  });
});
