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
const { stub } = require('sinon');

const { StartInputHandlerParser } = require('../../src/statementParsers/startInputHandlerParser');

describe('startInputHandlerParser', function() {
  const indent = '  ';

  const context = {
    directives: [],
    db: {
      write: function(key, value) {
        this[`${key}`] = value;
      },
      read: function(key) {
        return this[`${key}`];
      }
    },
    requestId: 'fakeRequestId'
  };

  const expression = {
    toLambda: function(options) {
      return JSON.stringify(testDirective);
    }
  }

  let errorStub = undefined;
  let location = undefined;
  let output = undefined;
  let parserInstance = undefined;
  let testDirective = undefined;

  describe('toLambda()', function() {
    beforeEach(function() {
      errorStub = stub(console, 'error');
      location = {
        start: {
          line: 3 // arbitrary line number
        }
      }

      context.db.__lastInputHandler = undefined;
      context.directives = [];
      output = [];

      testDirective = {
        type: "GameEngine.StartInputHandler",
        timeout: 1,
        recognizers: {
          "button pressed": {
            type: "match",
            fuzzy: false,
            anchor: "end",
            pattern: [{ action: 'down' }]
          }
        },
        events: {
          "NewButton": {
            meets: ["button pressed"],
            reports: "history",
            maximumInvocations: 4,
            shouldEndInputHandler: false
          }
        }
      }

      parserInstance = new StartInputHandlerParser(location, expression);
    });

    afterEach(function() {
      errorStub.restore();
    });

    it('sets correct line attribute', async function() {
      expect(parserInstance.line).to.equal(3);
      location = undefined;
      parserInstance = new StartInputHandlerParser(location, expression);
      expect(parserInstance.line).to.equal('[undefined]');

      location = {};
      parserInstance = new StartInputHandlerParser(location, expression);
      expect(parserInstance.line).to.equal('[undefined]');
    });

    it('adds valid StartInputHandler logic to output', async function() {
      parserInstance.toLambda(output, indent);

      expect(output.length).to.equal(1);
      const lambdaCode = output[0];
      await eval(`(async function(){${lambdaCode}})()`);

      expect(context.db['__lastInputHandler']).to.equal('fakeRequestId');
    });

    it('fails on missing StartInputHandler directive', async function() {
      testDirective = undefined;
      parserInstance.toLambda(output, indent);

      const lambdaCode = output[0];
      await eval(`(async function(){${lambdaCode}})()`);

      expect(errorStub.callCount).to.equal(1);
      expect(errorStub.firstCall.args[0]).to.deep.equal(
        "Expression at line 3 did not return anything: It should return an object definition for a single 'GameEngine.StartInputHandler' directive."
      )
    });

    it('fails on invalid StartInputHandler directive type', async function() {
      testDirective = 'invalidDirective';
      parserInstance.toLambda(output, indent);

      const lambdaCode = output[0];
      await eval(`(async function(){${lambdaCode}})()`);

      expect(errorStub.callCount).to.equal(1);
      expect(errorStub.firstCall.args[0]).to.deep.equal(
        "Expression at line 3 didn't return an object: It should return an object definition for a single 'GameEngine.StartInputHandler' directive."
      )
    });

    it('fails on invalid directive data type', async function() {
      testDirective.type = 'InvalidType';
      parserInstance.toLambda(output, indent);

      const lambdaCode = output[0];
      await eval(`(async function(){${lambdaCode}})()`);

      expect(errorStub.callCount).to.equal(1);
      expect(errorStub.firstCall.args[0]).to.deep.equal(
        "Object returned at line 3 at directive type 'InvalidType': It should have the type 'GameEngine.StartInputHandler'."
      )
    });
  });

  describe('collectRequiredAPIs()', function() {
    beforeEach(function() {
      parserInstance = new StartInputHandlerParser(location);
    });

    it('adds the GAME_ENGINE api', function() {
      let apis = {};
      parserInstance.collectRequiredAPIs(apis);
      apis['GAME_ENGINE'].should.be.true;
    });
  });
});
