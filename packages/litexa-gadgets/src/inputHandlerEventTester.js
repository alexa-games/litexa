/*
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved.
 * These materials are licensed as 'Restricted Program Materials' under the Program Materials
 * License Agreement (the 'Agreement') in connection with the Amazon Alexa voice service.
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html.
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized
 * terms not defined in this file have the meanings given to them in the Agreement.
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

module.exports = function (lib) {
  const {
    makeBaseRequest,
    makeHandlerIdentity,
    makeRequestId,
    padStringWithChars
  } = lib.TestUtils;

  return class InputHandlerEventTestStep extends lib.ResponseGeneratingStep {
    constructor(location, source = '') {
      super();
      this.location = location;

      this.inputEvents = [];
      this.description = '';
      this.eventNames = [];
      this.sourceFileName = '';

      // Set a fixed cadence of at least 30 seconds between the usual input events.
      this.testingTimeIncrement = 30000;
      this.isInputHandlerEventTestStep = true;

      // Determine whether our test step was constructed with an asset name, a single event, or an
      // array of events.
      this.evaluateSource(source);
    }

    evaluateSource(source) {
      if (typeof (source) === 'string') {
        this.eventNames = [source];
      } else if (Array.isArray(source)) {
        this.eventNames = source;
      } else {
        this.sourceFileName = source.toString();
      }
    }

    pushAction({ gadgetId, action, color }) {
      this.inputEvents.push({
        gadgetId,
        timeStamp: new Date().toISOString(),
        action,
        color
      });
    }

    run({ skill, lambda, context, resultCallback }) {
      let events = [];

      if (this.sourceFileName) {
        const fileContents = skill.getFileContents(this.sourceFileName, skill.testLanguage);
        events = this.getEventsFromFileContents(fileContents, resultCallback);
      } else {
        events = this.createEventsFromEventNames();
      }

      const requestBody = makeBaseRequest(skill);
      const identity = makeHandlerIdentity(skill);
      this.addInputHandlerEventToRequest({
        requestBody,
        events,
        time: context.time,
        locale: skill.testLanguage
      });

      requestBody.request.originatingRequestId = context.db.getVariables(identity).__lastInputHandler;

      const result = {
        testEvents: events, // just a shortcut for request.events
        expectationsMet: true,
        event: requestBody,
        errors: [],
        logs: []
      }
      this.processEvent({ result, skill, lambda, context, resultCallback });
    }

    getEventsFromFileContents(fileContents, resultCallback) {
      if (fileContents == null) {
        resultCallback(`InputHandlerEvent source file '${this.sourceFileName}' not found.`);
        return [];
      }

      let events = [];
      if (Array.isArray(fileContents)) {
        events = fileContents;
      } else if (fileContents.constructor === Object) {
        events = [fileContents];
      } else {
        const errMsg = [
          `InputHandlerEvent source file '${this.sourceFileName}' didn't contain the expected array of input handler events.`,
          'See the @litexa/gadgets/README.md for more information.'
        ].join(' ');

        resultCallback(errMsg);
        return [];
      }

      const names = [];
      let count = 0;
      events.forEach(event => {
        names.push(event.name);
        if (event.inputEvents) {
          count += event.inputEvents.length;
        }
      });

      this.description = `${names.join(',')}[${count}]`;
      return events;
    }

    createEventsFromEventNames() {
      let events = [];
      let inputEvents = this.inputEvents || [];
      this.eventNames.forEach(eventName => {
        events.push({
          name: eventName,
          inputEvents
        })
      });

      this.description = `${this.eventNames}[${inputEvents}]`;
      return events;
    }

    addInputHandlerEventToRequest({ requestBody, events, time, locale }) {
      requestBody.request = {
        type: 'GameEngine.InputHandlerEvent',
        requestId: makeRequestId(),
        timestamp: new Date(time).toISOString(),
        locale,
        events
      };
    };

    report({ err, logs, sourceLine, step, result, context }) {
      if (err != null) {
        logs.push(`${sourceLine} ⦿⦿ ${err}`);
        return;
      }

      const skill = context.skill;
      const time = (new Date(context.time)).toLocaleString();

      const events = result.testEvents;
      let eventNames = '';
      if (events != null) {
        if (Array.isArray(events)) {
          const results = [];
          events.forEach(event => {
            results.push(event.name);
          });
          eventNames = results.join(', ');
        } else {
          console.error(`InputHandlerEventTestStep encountered events of type '${typeof(events)}' -> expecting an array.`);
          return;
        }
        eventNames = padStringWithChars({
          str: eventNames,
          targetLength: skill.maxStateNameLength + 2,
          paddingChar: ' '
        });
      } else {
        eventNames = padStringWithChars({
          str: 'MISSING EVENT',
          targetLength: skill.maxStateNameLength + 2,
          paddingChar: ' '
        });
      }
      if (step.sourceFileName !== '') {
        logs.push(`${sourceLine} ⦿⦿ ${eventNames} ${step.sourceFileName} @ ${time}`);
      } else {
        logs.push(`${sourceLine} ⦿⦿ ${eventNames} @ ${time}`);
      }
    }
  }
}
