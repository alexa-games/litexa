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

class StartInputHandlerParser {
  constructor(location, expression) {
    if (location != null && location.start != null) {
      this.line = location.start.line || '[undefined]';
    } else {
      this.line = '[undefined]';
    }
    this.expression = expression;
  }

  collectRequiredAPIs(apis) {
    return apis['GAME_ENGINE'] = true;
  }

  toLambda(output, indent, options) {
    const expression = this.expression.toLambda(options);

    /*
    startInputHandler:
      1) ensures only one directive of its kind is present, favoring the last submitted
      2) ensures the directive has the correct type
      3) records the current requestId, to be later used as the originatingRequestId
     */

    // Istanbul needs to ignore this function, because nyc will otherwise insert cov_(...)[]++
    // coverage markers, which break later evaluating the function.
    /* istanbul ignore next */
    const lambdaCode = async function(context) {
      context.directives = context.directives.filter((directive) => {
        const isStartDirective = (directive.type === 'GameEngine.StartInputHandler');
        if (isStartDirective) {
          console.warn(`WARNING: Encountered duplicate startInputHandler at line ${this.line}. The previous one will be removed.`);
        }
        return !isStartDirective;
      });

      // Let's check for issues with our directive.
      const __directive = expression;
      if (__directive == null) {
        throw new Error(`Expression at line ${this.line} did not return anything: It should return an object definition for a single 'GameEngine.StartInputHandler' directive.`);
      } else if (__directive.constructor !== Object) {
        throw new Error(`Expression at line ${this.line} didn't return an object: It should return an object definition for a single 'GameEngine.StartInputHandler' directive.`);
      } else if (__directive.type !== 'GameEngine.StartInputHandler') {
        throw new Error(`Object returned at line ${this.line} at directive type '${__directive.type}': It should have the type 'GameEngine.StartInputHandler'.`);
      }

      // If everything was okay, push the directive and originatingRequestId.
      context.directives.push(__directive);
      context.db.write('__lastInputHandler', context.requestId);
    }

    // Stringify our lambda code, to be inserted in the lambda output.
    let stringifiedCode = String(lambdaCode);

    // Replace StartInputHandlerParser variables with their values in the stringified code.
    stringifiedCode = stringifiedCode.replace(/\${this.line}/g, `${this.line}`);
    stringifiedCode = stringifiedCode.replace(/(const\s*__directive\s*=\s*)expression/g, `$1${expression};`);

    // Clean up the indentation -> the above toString() indents with 4 spaces.
    stringifiedCode = stringifiedCode.replace(/\n    /g, `\n${indent}  `)

    output.push(`${indent}await (${stringifiedCode})(context).catch(err => console.error(err.message))`)
  }
};

module.exports = {
  StartInputHandlerParser
}
