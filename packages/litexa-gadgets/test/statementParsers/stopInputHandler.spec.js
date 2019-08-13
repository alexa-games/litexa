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

const { StopInputHandlerParser } = require('../../src/statementParsers/stopInputHandler');

describe('stopInputHandlerParser', function() {
  const parserInstance = new StopInputHandlerParser();
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
    }
  };

  let logStub = undefined;
  let output = undefined;

  describe('toLambda()', function() {
    beforeEach(function() {
      logStub = stub(console, 'log');

      context.db.__lastInputHandler = undefined;
      context.directives = [];
      output = [];

      testDirective = {
        type: "GameEngine.StopInputHandler",
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
    });

    afterEach(function() {
      logStub.restore();
    });

    it('does nothing if existing StopInputHandler directive is found in context', async function() {
      const directive = {
        type: 'GameEngine.StopInputHandler',
        originatingRequestId: 'fakeOriginatingRequestId'
      }
      context.directives.push(directive);

      parserInstance.toLambda(output, indent);
      expect(output.length).to.equal(1);
      const lambdaCode = output[0];
      await eval(`(async function(){${lambdaCode}})()`);

      // Make sure we didn't push a second directive.
      expect(context.directives).to.deep.equal([ directive ]);
    });

    it('does nothing if no __lastInputHandler entry found in DB', async function() {
      parserInstance.toLambda(output, indent);
      const lambdaCode = output[0];
      await eval(`(async function(){${lambdaCode}})()`);

      expect(context.directives).to.deep.equal([]);
      expect(logStub.callCount).to.equal(1);
      expect(logStub.firstCall.args[0]).to.deep.equal(
        'WARNING: Did not send GameEngine.StopInputHandler because no current originatingRequestId was found in the database.'
      );
    });

    it('does nothing if __lastInputHandler in DB was previously cleared', async function() {
      context.__lastInputHandler = 'cleared';
      parserInstance.toLambda(output, indent);
      const lambdaCode = output[0];
      await eval(`(async function(){${lambdaCode}})()`);

      expect(context.directives).to.deep.equal([]);
      expect(logStub.callCount).to.equal(1);
      expect(logStub.firstCall.args[0]).to.deep.equal(
        'WARNING: Did not send GameEngine.StopInputHandler because no current originatingRequestId was found in the database.'
      );
    });

    it('adds a GameEngine.StopInputHandler directive and clears __lastInputHandler, if all is fine', async function() {
      context.db.__lastInputHandler = 'fakeRequestId';
      parserInstance.toLambda(output, indent);
      const lambdaCode = output[0];
      await eval(`(async function(){${lambdaCode}})()`);

      const expectedDirective = {
        type: 'GameEngine.StopInputHandler',
        originatingRequestId: 'fakeRequestId'
      }

      expect(context.directives).to.deep.equal([ expectedDirective ]);
      expect(context.db.__lastInputHandler).to.equal('cleared');
    });
  });

  describe('collectRequiredAPIs()', function() {
    it('adds the GAME_ENGINE api', function() {
      let apis = {};
      parserInstance.collectRequiredAPIs(apis);
      apis['GAME_ENGINE'].should.be.true;
    });
  });
});
