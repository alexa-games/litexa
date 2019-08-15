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

const { StopCustomEventHandlerParser } = require('../../src/statementParsers/stopCustomEventHandler');

describe('stopCustomEventHandlerParser', function() {
  const parserInstance = new StopCustomEventHandlerParser();

  describe('toLambda()', function() {
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

    beforeEach(function() {
      logStub = stub(console, 'log');

      context.db.__lastCustomEventHandlerToken = undefined;
      context.directives = [];
      output = [];

      testDirective = {
        type: "CustomInterfaceController.StopEventHandler"
      };
    });

    afterEach(function() {
      logStub.restore();
    });

    it('does nothing if existing StopCustomEventHandler directive is found in context', async function() {
      const directive = {
        type: 'CustomInterfaceController.StopEventHandler',
        token: 'fakeToken'
      }
      context.directives.push(directive);

      parserInstance.toLambda(output, indent);
      expect(output.length).to.equal(1);
      const lambdaCode = output[0];
      await eval(`(async function(){${lambdaCode}})()`);

      // Make sure we didn't push a second directive.
      expect(context.directives).to.deep.equal([ directive ]);
    });

    it('does nothing if no __lastCustomEventHandlerToken found in DB', async function() {
      parserInstance.toLambda(output, indent);
      const lambdaCode = output[0];
      await eval(`(async function(){${lambdaCode}})()`);

      expect(context.directives).to.deep.equal([]);
      expect(logStub.callCount).to.equal(1);
      expect(logStub.firstCall.args[0]).to.deep.equal(
        'WARNING: Did not send CustomInterfaceController.StopEventHandler because no current handler token was found in the database.'
      );
    });

    it('does nothing if __lastCustomEventHandlerToken in DB was previously cleared', async function() {
      context.__lastCustomEventHandlerToken = 'cleared';
      parserInstance.toLambda(output, indent);
      const lambdaCode = output[0];
      await eval(`(async function(){${lambdaCode}})()`);

      expect(context.directives).to.deep.equal([]);
      expect(logStub.callCount).to.equal(1);
      expect(logStub.firstCall.args[0]).to.deep.equal(
        'WARNING: Did not send CustomInterfaceController.StopEventHandler because no current handler token was found in the database.'
      );
    });

    it('adds a CustomInterfaceController.StopEventHandler directive and clears __lastCustomEventHandlerToken, if all is fine', async function() {
      context.db.__lastCustomEventHandlerToken = 'fakeRequestId';
      parserInstance.toLambda(output, indent);
      const lambdaCode = output[0];
      await eval(`(async function(){${lambdaCode}})()`);

      const expectedDirective = {
        type: 'CustomInterfaceController.StopEventHandler',
        token: 'fakeRequestId'
      }

      expect(context.directives).to.deep.equal([ expectedDirective ]);
      expect(context.db.__lastCustomEventHandlerToken).to.equal('cleared');
    });
  });

  describe('collectRequiredAPIs()', function() {
    it('adds the CUSTOM_INTERFACE api', function() {
      let apis = {};
      parserInstance.collectRequiredAPIs(apis);
      apis['CUSTOM_INTERFACE'].should.be.true;
    });
  });
});
