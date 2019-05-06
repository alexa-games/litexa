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

const stringBuilder = require('./aplParserHelpers').ObjectStringBuilder;
const {
  isValidCmdType,
  isValidCmdParam,
  getValidCmdTypes,
  getValidCmdParams
} = require('./aplCommandInfo');

module.exports = function(lib) {
  return function (commandType = undefined) {
    this.attributes = {
      commands: {type: commandType}
    };

    this.pushAttribute = function(location, key, value) {
      let param = key;
      if (param === 'type') {
        if (!isValidCmdType(value)) {
          throw new lib.ParserError(location, `Invalid command type '${value}' found, expecting one of ${getValidCmdTypes()}.`);
        }
      } else {
        let type = this.attributes.commands.type;
        if (!isValidCmdParam(type, param)) {
          throw new lib.ParserError(location, `Invalid command parameter '${param}' found, expecting one of ${getValidCmdParams(type)}.`);
        }
      }
      this.attributes.commands[param] = value;
      // @TODO: If we decide to support this aplcommand statement, we could also add typechecks for the attribute values here.
    }

    this.toLambda = function(output, indent, options) {

      let aplString = stringBuilder.parseAndStringify({
        options,
        indent,
        attributes: this.attributes,
        ParserError: lib.ParserError
      });

      output.push(`context.apl = context.apl || [];`);
      output.push(`context.apl.push(${aplString});`);

      // Let's add a speech marker, which will allow us to push speech into ExecuteCommands.
      output.push(`context.aplSpeechMarkers = context.aplSpeechMarkers || [];`);
      output.push(`context.aplSpeechMarkers.push(context.say.length);`)
    }

    this.collectRequiredAPIs = function(apis) {
      apis['ALEXA_PRESENTATION_APL'] = true;
    }
  };
}
