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

const { expect, should } = require('chai');
should();

const fakeLib = {
  EventIntent: class EventIntent {
    toLambda(output, options) {
    }
  }
}

const initInputHandlerEventParser = require('../../src/statementParsers/inputHandlerEventParser');
const InputHandlerEventParser = initInputHandlerEventParser(fakeLib);

describe('stopInputHandlerParser', function() {
  const parserInstance = new InputHandlerEventParser();

  const context = {
    directives: [],
    db: {
      write: function(key, value) {
        this[`${key}`] = value;
      },
      read: function(key) {
        return this[`${key}`];
      }
    }
  };

  let output = undefined;

  describe('toLambda()', function() {
    beforeEach(function() {
      output = [];
      context.shouldDropSession = undefined;
    });

    it("sets shouldDropSession when an InputHandlerEvent requestId mismatches the last input handler's originatingRequestId", async function() {
      context.request = {
        originatingRequestId: 'newRequestId'
      }
      context.db.__lastInputHandler = 'oldRequestId';

      parserInstance.toLambda(output);
      expect(output.length).to.equal(1);
      const lambdaCode = output[0];
      await eval(`(async function(){${lambdaCode}})()`);

      expect(context.shouldDropSession).to.be.true;
    });

    it("doesn't set shouldDropSession when an InputHandlerEvent requestId matches the last input handler's originatingRequestId", async function() {
      context.request = {
        originatingRequestId: 'requestId'
      }
      context.db.__lastInputHandler = 'requestId';

      parserInstance.toLambda(output);
      const lambdaCode = output[0];
      await eval(`(async function(){${lambdaCode}})()`);

      expect(context.shouldDropSession).to.be.undefined;
    });
  });
});
