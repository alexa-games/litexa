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

const {
  startInputHandlerDirectiveValidator,
  stopInputHandlerDirectiveValidator
} = require('./src/validators/gameEngineDirectiveValidators');

const {
  setLightDirectiveValidator
} = require('./src/validators/gadgetControllerDirectiveValidators');

const { modelValidatorForGadgets } = require('./src/validators/modelValidator');
const { manifestValidatorForGadgets } = require('./src/validators/manifestValidator');

const initInputHandlerEventParser = require('./src/statementParsers/inputHandlerEventParser');
const { StartInputHandlerParser } = require('./src/statementParsers/startInputHandlerParser');
const { StopInputHandlerParser } = require('./src/statementParsers/stopInputHandlerParser');

const initInputHandlerEventTester = require(`./src/inputHandlerEventTester`);

module.exports = function(options, lib) {
  const compiler = {
    validators: {
      directives: {
        'GameEngine.StartInputHandler': startInputHandlerDirectiveValidator,
        'GameEngine.StopInputHandler': stopInputHandlerDirectiveValidator,
        'GadgetController.SetLight': setLightDirectiveValidator
      },
      model: modelValidatorForGadgets,
      manifest: manifestValidatorForGadgets
    },
    validEventNames: [
      'GameEngine.InputHandlerEvent'
    ]
  }

  const language = {
    statements: {
      startInputHandler: {
        parser: `startInputHandler
          = 'startInputHandler' ___ expression:ExpressionString {
            pushCode(location(), new lib.StartInputHandler(location(), expression));
          }`
      },
      stopInputHandler: {
        parser: `stopInputHandler
          = 'stopInputHandler' {
            pushCode(location(), new lib.StopInputHandler());
          }`
      },
      WhenGameEngineInputHandlerEvent: {
        parser: `WhenGameEngineInputHandlerEvent
          = 'when' ___ 'GameEngine.InputHandlerEvent' __ name:QuotedString {
            const intent = pushIntent(location(), 'GameEngine.InputHandlerEvent', {class:lib.InputHandlerEventIntent});
            intent.setCurrentEventName(name);
          }
          / 'when' ___ 'GameEngine.InputHandlerEvent' {
            const intent = pushIntent(location(), 'GameEngine.InputHandlerEvent', {class:lib.InputHandlerEventIntent});
            intent.setCurrentEventName('__');
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
    },
    lib: {
      StartInputHandler: StartInputHandlerParser,
      StopInputHandler: StopInputHandlerParser,
      InputHandlerEventIntent: initInputHandlerEventParser(lib),
      InputHandlerEventTestStep: initInputHandlerEventTester(lib)
    }
  }

  return { compiler, language };
};
