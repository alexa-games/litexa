/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
