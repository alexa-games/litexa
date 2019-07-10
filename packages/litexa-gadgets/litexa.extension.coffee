
###

 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved.
 * These materials are licensed as "Restricted Program Materials" under the Program Materials
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service.
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html.
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized
 * terms not defined in this file have the meanings given to them in the Agreement.
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

###


path = require 'path'
fs = require 'fs'

requirePrefix = 'lib'
if __filename.indexOf('.coffee') > 0
  requirePrefix = 'src'

module.exports = (options, lib) ->
  language =
    statements: {}
    testStatements: {}
    lib:
      StartInputHandler: require "./#{requirePrefix}/StartInputHandler"
      StopInputHandler: require "./#{requirePrefix}/StopInputHandler"
      InputHandlerEventIntent: require("./#{requirePrefix}/InputHandlerEventIntent")(lib)
      InputHandlerEventTestStep: require "./#{requirePrefix}/InputHandlerEventTestStep"

  language.statements.startInputHandler =
    parser: """
      startInputHandler
      = "startInputHandler" ___ expression:ExpressionString {
        pushCode(location(), new lib.StartInputHandler(expression));
      }
    """

  language.statements.stopInputHandler =
    parser: """
      stopInputHandler
      = "stopInputHandler" {
        pushCode(location(), new lib.StopInputHandler());
      }
    """

  language.statements.WhenGameEngineInputHandlerEvent =
    parser: """
      WhenGameEngineInputHandlerEvent
      = "when" ___ "GameEngine.InputHandlerEvent" __ name:QuotedString {
        const intent = pushIntent(location(), "GameEngine.InputHandlerEvent", {class:lib.InputHandlerEventIntent});
        intent.setCurrentEventName(name);
      }
      / "when" ___ "GameEngine.InputHandlerEvent" {
        const intent = pushIntent(location(), "GameEngine.InputHandlerEvent", {class:lib.InputHandlerEventIntent});
        intent.setCurrentEventName('__');
      }
    """

  language.testStatements.inputHandlerEvent =
    parser: """
      inputHandlerEvent
      = "inputHandlerEvent" ___ first:QuotedString rest:inputHandlerEventListTail+  {
        rest.unshift(first);
        currentTest().pushTestStep(new lib.InputHandlerEventTestStep(location(), rest));
      }
      / "inputHandlerEvent" ___ name:QuotedString {
        currentTest().pushTestStep(new lib.InputHandlerEventTestStep(location(), name));
      }
      / "inputHandlerEvent" ___ name:AssetName {
        currentTest().pushTestStep(new lib.InputHandlerEventTestStep(location(), name));
      }

      inputHandlerEventListTail
      = __ "," __ name:QuotedString { return name; }
    """

  language.testStatements.inputHandlerAction =
    parser: """
      inputHandlerAction
      = "inputHandlerAction" ___ id:Identifier ___ event:InputHandlerActionType ___ color:HexColor {
        var step = currentTest().findLastStep((s) => {return s.isInputHandlerEventTestStep;});
        if (step == null) {
          throw new ParserError(location(), "could not find an inputHandlerEvent to add an action to here");
        }
        step.pushAction(location(), id, event, color);
      }
      / "inputHandlerAction" ___ id:Identifier ___ event:InputHandlerActionType {
        var step = currentTest().findLastStep((s) => {return s.isInputHandlerEventTestStep;});
        if (step == null) {
          throw new ParserError(location(), "could not find an inputHandlerEvent to add an action to here");
        }
        step.pushAction(location(), id, event, 'FFFFFF');
      }

      InputHandlerActionType
      = "up" / "down"
    """

  compiler =
    validEventNames: [
      'GameEngine.InputHandlerEvent'
    ]
    validators:
      directives:
        'GameEngine.StartInputHandler': require "./#{requirePrefix}/GameEngine.StartInputHandler"
        'GameEngine.StopInputHandler': require "./#{requirePrefix}/GameEngine.StopInputHandler"
        'GadgetController.SetLight': require "./#{requirePrefix}/GadgetController.SetLight"
      model: require "./#{requirePrefix}/modelValidator.coffee"
      manifest: require "./#{requirePrefix}/manifestValidator.coffee"

  return { language, compiler }
