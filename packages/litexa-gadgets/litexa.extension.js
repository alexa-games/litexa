/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const {
  startInputHandlerDirectiveValidator,
  stopInputHandlerDirectiveValidator
} = require('./src/validators/gameEngineDirectiveValidators');

const {
  setLightDirectiveValidator
} = require('./src/validators/gadgetControllerDirectiveValidators');

const {
  sendDirectiveValidator,
  startEventHandlerDirectiveValidator,
  stopEventHandlerDirectiveValidator
} = require('./src/validators/customInterfaceDirectiveValidators');

const { modelValidatorForGadgets } = require('./src/validators/modelValidator');
const { manifestValidatorForGadgets } = require('./src/validators/manifestValidator');

const { StartInputHandlerParser } = require('./src/statementParsers/startInputHandler');
const { StopInputHandlerParser } = require('./src/statementParsers/stopInputHandler');

const { StartCustomEventHandlerParser } = require('./src/statementParsers/startCustomEventHandler');
const { StopCustomEventHandlerParser } = require('./src/statementParsers/stopCustomEventHandler');

const initInputHandlerEventTester = require(`./src/inputHandlerEventTester`);

module.exports = function(options, lib) {
  const compiler = {
    validators: {
      directives: {
        'GameEngine.StartInputHandler': startInputHandlerDirectiveValidator,
        'GameEngine.StopInputHandler': stopInputHandlerDirectiveValidator,
        'GadgetController.SetLight': setLightDirectiveValidator,
        'CustomInterfaceController.SendDirective': sendDirectiveValidator,
        'CustomInterfaceController.StartEventHandler': startEventHandlerDirectiveValidator,
        'CustomInterfaceController.StopEventHandler': stopEventHandlerDirectiveValidator
      },
      model: modelValidatorForGadgets,
      manifest: manifestValidatorForGadgets
    },
    validEventNames: [
      'GameEngine.InputHandlerEvent',
      'CustomInterfaceController.EventsReceived',
      'CustomInterfaceController.Expired'
    ]
  }

  const language = {
    lib: {
      StartInputHandlerParser,
      StopInputHandlerParser,
      StartCustomEventHandlerParser,
      StopCustomEventHandlerParser,
      InputHandlerEventTestStep: initInputHandlerEventTester(lib)
    },
    statements: {
      startInputHandler: {
        parser: `startInputHandler
          = 'startInputHandler' ___ expression:ExpressionString {
            pushCode(location(), new lib.StartInputHandlerParser(location(), expression));
          }`
      },
      stopInputHandler: {
        parser: `stopInputHandler
          = 'stopInputHandler' {
            pushCode(location(), new lib.StopInputHandlerParser());
          }`
      },
      startCustomEventHandler: {
        parser: `startCustomEventHandler
          = 'startCustomEventHandler' ___ expression:ExpressionString {
            pushCode(location(), new lib.StartCustomEventHandlerParser(location(), expression));
          }`
      },
      stopCustomEventHandler: {
        parser: `stopCustomEventHandler
          = 'stopCustomEventHandler' {
            pushCode(location(), new lib.StopCustomEventHandlerParser());
          }`
      },
      WhenGameEngineInputHandlerEvent: {
        parser: `WhenGameEngineInputHandlerEvent
          = 'when' ___ 'GameEngine.InputHandlerEvent' __ name:QuotedString {
            const intent = pushIntent(location(), 'GameEngine.InputHandlerEvent', {class:lib.FilteredIntent});

            intent.setCurrentIntentFilter({
              name,
              data: { name },
              filter: function(request, data) {
                if (request.events != null) {
                  for (const __event of request.events) {
                    if (__event.name === data.name) {
                      context.slots.event = __event;
                      return true;
                    }
                  }
                  return false;
                }
              },
              callback: async function() {
                if (context.db.read('__lastInputHandler') != context.request.originatingRequestId) {
                  context.shouldDropSession = true;
                  return;
                }
              }
            });
          }
          / 'when' ___ 'GameEngine.InputHandlerEvent' {
            const intent = pushIntent(location(), 'GameEngine.InputHandlerEvent', {class:lib.FilteredIntent});
            intent.setCurrentIntentFilter({
              name: '__'
            });
          }`
      },
      WhenCustomInterfaceControllerEvents: {
        parser: `WhenCustomInterfaceControllerEvents
          = 'when' ___ 'CustomInterfaceController.EventsReceived' ___ namespace:QuotedString {
            const intent = pushIntent(location(), 'CustomInterfaceController.EventsReceived', {class:lib.FilteredIntent});

            intent.setCurrentIntentFilter({
              name: namespace,
              data: { namespace },
              filter: function(request, data) {
                if (request.events != null) {
                  for (const __event of request.events) {
                    if (__event.header.namespace === data.namespace) {
                      context.slots.event = __event;
                      return true;
                    }
                  }
                  return false;
                }
              },
              callback: async function() {
                if (context.db.read('__lastCustomEventHandlerToken') != context.request.token) {
                  context.shouldDropSession = true;
                  return;
                }
              }
            });
          }
          / 'when' ___ 'CustomInterfaceController.EventsReceived' {
            const intent = pushIntent(location(), 'CustomInterfaceController.EventsReceived', {class:lib.FilteredIntent});
            intent.setCurrentIntentFilter({
              name: '__'
            });
          }`
      }
    },
    testStatements: {
      inputHandlerEvent: {
        parser: `inputHandlerEvent
          = 'inputHandlerEvent' ___ first:QuotedString rest:inputHandlerEventListTail+ {
            rest.unshift(first);
            currentTest().pushTestStep(new lib.InputHandlerEventTestStep(location(), rest));
          }
          / 'inputHandlerEvent' ___ name:QuotedString {
            currentTest().pushTestStep(new lib.InputHandlerEventTestStep(location(), name));
          }
          / 'inputHandlerEvent' ___ name:AssetName {
            currentTest().pushTestStep(new lib.InputHandlerEventTestStep(location(), name));
          }

          inputHandlerEventListTail = __ ',' __ name:QuotedString { return name; }`
      },
      inputHandlerAction: {
        parser: `inputHandlerAction
          = 'inputHandlerAction' ___ gadgetId:Identifier ___ action:InputHandlerActionType ___ color:HexColor {
            const step = currentTest().findLastStep((s) => {return s.isInputHandlerEventTestStep;});
            if (step == null) {
              throw new ParserError(location(), 'could not find an inputHandlerEvent to add an action to here');
            }
            step.pushAction({ gadgetId, action, color });
          }
          / 'inputHandlerAction' ___ gadgetId:Identifier ___ action:InputHandlerActionType {
            const step = currentTest().findLastStep((s) => {return s.isInputHandlerEventTestStep;});
            if (step == null) {
              throw new ParserError(location(), 'could not find an inputHandlerEvent to add an action to here');
            }
            step.pushAction({ gadgetId, action, color: 'FFFFFF' });
          }

          InputHandlerActionType = 'up' / 'down'`
      }
    }
  }

  return { compiler, language };
};
