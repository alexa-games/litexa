/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

class StopCustomEventHandlerParser {
  collectRequiredAPIs(apis) {
    return apis['CUSTOM_INTERFACE'] = true;
  }

  toLambda(output, indent, options) {
    /*
    stopCustomEventHandler:
      Checks the DB for the token of the last startCustomEventHandler statement.
      1) If no token is found or the most recent token was already cleared by a
      stopCustomEventHandler, warning is logged and no action is taken.
      2) If a valid token is found, a CustomInterfaceController.StopEventHandler directive is sent
      for that token.
     */

    // Istanbul needs to ignore this function, because nyc will otherwise insert cov_(...)[]++
    // coverage markers, which break later evaluating the function.
    /* istanbul ignore next */
    const lambdaCode = async function(context) {
      const __directive = context.directives.find((directive) => {
        directive.type === 'CustomInterfaceController.StopEventHandler';
      })
      if (__directive === undefined) {
        // We haven't already sent a StopInputHandler, so send one now.
        const lastToken = context.db.read('__lastCustomEventHandlerToken');
        if (lastToken != null && lastToken !== 'cleared') {
          context.directives.push({
            type:'CustomInterfaceController.StopEventHandler',
            token: lastToken
          });
          context.db.write('__lastCustomEventHandlerToken', 'cleared');
        } else {
          console.log('WARNING: Did not send CustomInterfaceController.StopEventHandler because no current handler token was found in the database.');
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
  StopCustomEventHandlerParser
}
