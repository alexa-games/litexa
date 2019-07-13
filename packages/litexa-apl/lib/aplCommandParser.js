/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const stringBuilder = require('./aplParserHelpers').ObjectStringBuilder;
const {
  isValidCmdType,
  isValidCmdParam,
  getValidCmdTypes,
  getValidCmdParams
} = require('./aplCommandInfo');

module.exports = function(lib) {
  return function(commandType = undefined) {
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
