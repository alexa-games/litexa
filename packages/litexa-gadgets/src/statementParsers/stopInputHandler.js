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

class StopInputHandlerParser {
  collectRequiredAPIs(apis) {
    return apis['GAME_ENGINE'] = true;
  }

  toLambda(output, indent, options) {
    /*
    stopInputHandler:
      Checks the DB for the originatingRequestId of the last startInputHandler statement.
      1) If no request ID is found, or the last requestId was already cleared by a stopInputHandler,
      warning is logged and no action is taken.
      2) If a valid request ID is found, a GameEngine.StopInputHandler directive is sent for that ID.
     */

    // Istanbul needs to ignore this function, because nyc will otherwise insert cov_(...)[]++
    // coverage markers, which break later evaluating the function.
    /* istanbul ignore next */
    const lambdaCode = async function(context) {
      const __directive = context.directives.find((directive) => {
        directive.type === 'GameEngine.StopInputHandler';
      })
      if (__directive === undefined) {
        // We haven't already sent a StopInputHandler, so send one now.
        const lastId = context.db.read('__lastInputHandler');
        if (lastId != null && lastId !== 'cleared') {
          context.directives.push({
            type:'GameEngine.StopInputHandler',
            originatingRequestId: lastId
          });
          context.db.write('__lastInputHandler', 'cleared');
        } else {
          console.log('WARNING: Did not send GameEngine.StopInputHandler because no current originatingRequestId was found in the database.');
        }
      }
    };

    // Stringify our lambda code, to be inserted in the lambda output.
    let stringifiedCode = lambdaCode.toString();
    // Clean up the indentation -> the above toString() indents with 4 spaces.
    stringifiedCode = stringifiedCode.replace(/    /g, `${indent}  `)

    output.push(`${indent}await (${stringifiedCode})(context)`)
  }
};

module.exports = {
  StopInputHandlerParser
}
