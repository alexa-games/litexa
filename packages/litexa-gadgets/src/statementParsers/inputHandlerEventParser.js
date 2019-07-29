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

module.exports = function(lib) {

  return class InputHandlerEventIntent extends lib.EventIntent {

    toLambda(output, options) {
      const indent = '    ';

      // `when GameEngine.InputHandlerEvent` checks if the current requestId matches the
      // current originatingRequestId. If it doesn't, it will drop the current shouldEndSession.

      // Istanbul needs to ignore this function, because nyc will otherwise insert cov_(...)[]++
      // coverage markers, which break later evaluating the function.
      /* istanbul ignore next */
      const lambdaCode = async function(context) {
        if (context.db.read('__lastInputHandler') != context.request.originatingRequestId) {

          context.shouldDropSession = true;
          return;
        }
      }

      // Stringify our lambda code, to be inserted in the lambda output.
      let stringifiedCode = lambdaCode.toString();
      // No need to clean up indentation.

      output.push(`${indent}await (${stringifiedCode})(context);`)
      // Call the EventIntent toLambda, which will evaluate the event name if one is specified.
      return super.toLambda(output, options);
    }
  }
}
