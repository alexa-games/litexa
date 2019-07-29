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
const { spy, stub, useFakeTimers } = require('sinon');

const initInputHandlerEventTestStep = require('../src/inputHandlerEventTester');
require('coffeescript').register();
const { lib } = require('@litexa/core/src/parser/testing');
const InputHandlerEventTestStep = initInputHandlerEventTestStep(lib);

describe('inputHandlerEventTester', function() {
  const context = {
    skill: {
      maxStateNameLength: 16
    },
    time: new Date().getTime()
  }
  const location = {
    start: {
      line: 3 // arbitrary line number
    }
  }

  const now = new Date();
  let clock = undefined;

  let testStep = undefined;

  beforeEach(function() {
    clock = useFakeTimers(now.getTime());

    testStep.eventNames = [];
    testStep.sourceFileName = '';
  });

  afterEach(function() {
    clock.restore();
  });

  it('accepts all valid source types', function() {
    testStep = new InputHandlerEventTestStep(location, 'EventName');
    expect(testStep.eventNames).to.deep.equal(['EventName']);

    testStep = new InputHandlerEventTestStep(location, ['EventName1', 'EventName2']);
    expect(testStep.eventNames).to.deep.equal(['EventName1', 'EventName2']);

    const file = {
      name: 'input',
      type: 'json'
    }
    testStep = new InputHandlerEventTestStep(location, file);
    expect(testStep.sourceFileName).to.deep.equal(file.toString());
  });

  it('pushAction adds an inputEvent', function() {
    testStep = new InputHandlerEventTestStep(location, 'EventName');

    const eventInput = {
      gadgetId: 'aGadgetId',
      action: 'down',
      color: '000000'
    }

    testStep.pushAction(eventInput);

    expect(testStep.inputEvents).to.deep.equal([
      {
        action: 'down',
        color: '000000',
        gadgetId: 'aGadgetId',
        timeStamp: new Date().toISOString()
      }
    ]);
  });

  describe('run()', function() {
    let fileContents = undefined;
    let stubProcessEvent = undefined;
    let resultCallbackSpy = undefined;
    const skill = {
      testLanguage: 'default',
      getFileContents: function(fileName, language) {
        return fileContents;
      }
    }

    const context = {
      time: new Date(),
      db: {
        getVariables: function(identity) {
          return this;
        },
        __lastInputHandler: 'runOriginatingRequestId'
      }
    }

    const fakeFunctions = {
      resultCallback: function(err) {
        return;
      }
    }

    beforeEach(function() {
      fileContents = undefined;
      testStep.eventNames = [];
      testStep.sourceFileName = '';

      testStep.pushAction({
        gadgetId: 'runGadgetId',
        action: 'down',
        color: '000000'
      });

      resultCallbackSpy = spy(fakeFunctions, 'resultCallback');
      stubProcessEvent = stub(testStep, 'processEvent');
    });

    afterEach(function() {
      resultCallbackSpy.restore();
      stubProcessEvent.restore();
    });

    it('calls processEvent with the expected result for eventNames', function() {
      testStep.eventNames = [
        'RunEvent'
      ]

      testStep.run({
        skill, context, resultCallback: fakeFunctions.resultCallback
      });

      expect(stubProcessEvent.callCount).to.equal(1);
      const requestBody = stubProcessEvent.firstCall.args[0].result;
      expect(requestBody.event.request).to.deep.equal({
        type: 'GameEngine.InputHandlerEvent',
        locale: 'default',
        originatingRequestId: 'runOriginatingRequestId',
        requestId: requestBody.event.request.requestId,
        timestamp: new Date(context.time).toISOString(),
        events: [
          {
            name: 'RunEvent',
            inputEvents: testStep.inputEvents
          }
        ]
      });
    });

    it('calls processEvent with the expected result for a source file with an array', function() {
      testStep.sourceFileName = 'fakeFileName';
      fileContents = [
        {
          name: 'BuzzedIn1',
          inputEvents: [
            {
              gadgetId: 'btn1',
              timestamp: new Date(context.time).toISOString(),
              action: 'down',
              color: 'FF0000'
            }
          ]
        },
        {
          name: 'BuzzedIn2',
          inputEvents: [
            {
              gadgetId: 'btn1',
              timestamp: new Date(context.time).toISOString(),
              action: 'down',
              color: 'FF0000'
            }
          ]
        }
      ]

      testStep.run({
        skill, context, resultCallback: fakeFunctions.resultCallback
      });

      expect(stubProcessEvent.callCount).to.equal(1);
      const requestBody = stubProcessEvent.firstCall.args[0].result;
      expect(requestBody.event.request).to.deep.equal({
        type: 'GameEngine.InputHandlerEvent',
        locale: 'default',
        originatingRequestId: 'runOriginatingRequestId',
        requestId: requestBody.event.request.requestId,
        timestamp: new Date(context.time).toISOString(),
        events: fileContents
      });
    });

    it('calls processEvent with the expected result for a source file with an object', function() {
      testStep.sourceFileName = 'fakeFileName';
      fileContents = {
        name: 'BuzzedIn1',
        inputEvents: [
          {
            gadgetId: 'btn1',
            timestamp: new Date(context.time).toISOString(),
            action: 'down',
            color: 'FF0000'
          }
        ]
      }

      testStep.run({
        skill, context, resultCallback: fakeFunctions.resultCallback
      });

      expect(stubProcessEvent.callCount).to.equal(1);
      const requestBody = stubProcessEvent.firstCall.args[0].result;
      expect(requestBody.event.request).to.deep.equal({
        type: 'GameEngine.InputHandlerEvent',
        locale: 'default',
        originatingRequestId: 'runOriginatingRequestId',
        requestId: requestBody.event.request.requestId,
        timestamp: new Date(context.time).toISOString(),
        events: [fileContents]
      });
    });

    it('calls resultCallback with appropriate error when source file has no contents', function() {
      testStep.sourceFileName = 'fakeFileName';
      fileContents = undefined;

      testStep.run({
        skill, context, resultCallback: fakeFunctions.resultCallback
      });

      expect(resultCallbackSpy.callCount).to.equal(1);
      expect(resultCallbackSpy.firstCall.args[0]).to.deep.equal(
        "InputHandlerEvent source file 'fakeFileName' not found."
      );
    });

    it('calls resultCallback with appropriate error when source file has invalid type of contents', function() {
      testStep.sourceFileName = 'fakeFileName';
      fileContents = 'invalidDataType';

      testStep.run({
        skill, context, resultCallback: fakeFunctions.resultCallback
      });

      expect(resultCallbackSpy.callCount).to.equal(1);
      expect(resultCallbackSpy.firstCall.args[0]).to.deep.equal(
        "InputHandlerEvent source file 'fakeFileName' didn't contain the expected array of input handler events. See the @litexa/gadgets/README.md for more information."
      );
    });
  });

  describe('report()', function() {
    const sourceLine = 3;
    const time = (new Date(context.time)).toLocaleString();

    let err = undefined;
    let logs = undefined;
    let result = undefined;
    let errorStub = undefined;

    testStep = new InputHandlerEventTestStep(location);

    beforeEach(function() {
      err = undefined;
      result = {};
      logs = [];

      testStep.eventNames = [];
      testStep.sourceFileName = '';

      errorStub = stub(console, 'error');
    });

    afterEach(function() {
      errorStub.restore();
    });

    it('reports accurate logs for existing events', function() {
      result.testEvents = [
        { name: 'Event1' }
      ]

      testStep.report({
        err, logs, sourceLine, step: testStep, result, context
      });

      expect(logs).to.deep.equal([
        `${sourceLine} ⦿⦿       Event1       @ ${time}`
      ]);

      logs = [];
      result.testEvents.push({ name: 'Event2' });
      testStep.report({
        err, logs, sourceLine, step: testStep, result, context
      });

      expect(logs).to.deep.equal([
        `${sourceLine} ⦿⦿   Event1, Event2   @ ${time}`
      ]);

      logs = [];
      result.testEvents.push({ name: 'Event3' });
      testStep.report({
        err, logs, sourceLine, step: testStep, result, context
      });

      expect(logs).to.deep.equal([
        `${sourceLine} ⦿⦿ Event1, Event2, Event3 @ ${time}`
      ]);
    });

    it('reports accurate log for missing event', function() {
      testStep.report({
        err, logs, sourceLine, step: testStep, result, context
      });

      expect(logs).to.deep.equal([
        `${sourceLine} ⦿⦿   MISSING EVENT    @ ${time}`
      ]);
    });

    it('reports errors', function() {
      err = new Error('AN ERROR');
      testStep.report({
        err, logs, sourceLine, step: testStep, result, context
      });

      expect(logs).to.deep.equal([
        `${sourceLine} ⦿⦿ ${err}`
      ]);
    });

    it("reports an error if events weren't an array", function() {
      result.testEvents = {};

      testStep.report({
        err, logs, sourceLine, step: testStep, result, context
      });

      expect(errorStub.callCount).to.equal(1);
      expect(errorStub.firstCall.args[0]).to.equal(
        "InputHandlerEventTestStep encountered events of type 'object' -> expecting an array."
      );
    });

    it("logs a file name, if defined", function() {
      const fileName = 'fakeFileName';
      testStep.sourceFileName = fileName;

      result.testEvents = [
        { name: 'Event1' }
      ]

      testStep.report({
        err, logs, sourceLine, step: testStep, result, context
      });

      expect(logs).to.deep.equal([
        `${sourceLine} ⦿⦿       Event1       ${fileName} @ ${time}`
      ]);
    });
  });
});
