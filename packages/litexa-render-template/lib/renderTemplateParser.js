/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const stringBuilder = require('./parserHelpers').ObjectStringBuilder;
const {TEMPLATE_INFO, VALID_TEMPLATE_TYPES, VALID_DISPLAY_SPEECH_AS_TYPES} = require('./renderTemplateInfo');

module.exports = function(lib) {

  return function(title = '', background = undefined) {
    this.attributes = {
      template: 'BodyTemplate1',
      title: title,
      background: background
    }

    this.toLambda = function(output, indent, options) {
      let screenString = stringBuilder.parseAndStringify({
        options,
        indent,
        attributes: this.attributes
      });

      output.push(`${indent}context.screen = ${screenString}`);
    }

    this.pushAttribute = function(location, key, value) {
      template = this.attributes.template;
      let supportedKeys = [];
      if (TEMPLATE_INFO.hasOwnProperty(template)) {
        supportedKeys = TEMPLATE_INFO[template].keys;
      }

      // 1) Check invalid keys.
      switch (key) {
        case 'template':
          break;
        case 'backgroundImage':
          throw new lib.ParserError(location, `Attribute '${key}' not supported > please use the equivalent 'background' instead.`);
        case 'listItems':
          throw new lib.ParserError(location, `Attribute '${key}' not supported > please use the equivalent 'list' instead.`);
        case 'backButton':
          throw new lib.ParserError(location, `Attribute '${key}' not supported > BACK button is auto-HIDDEN as it would close the skill.`);
        case 'textContent':
          throw new lib.ParserError(location, `Attribute '${key}' not supported > please use [primaryText, secondaryText, tertiaryText] instead.`);
        default:
          if (!supportedKeys.includes(key)) {
            throw new lib.ParserError(location, `Unsupported attribute '${key}' found in template '${template}' > expecting one of [${supportedKeys}]`);
          }
          break;
      }

      // 2) Check invalid values.
      switch (key) {
        case 'template':
          value = value.toString(); // in case user wrote the template name without quotes
          if (!VALID_TEMPLATE_TYPES.includes(value)) {
            throw new lib.ParserError(location, `Unrecognized template type '${value}' > expecting one of [${VALID_TEMPLATE_TYPES}]`)
          }
          break;

        case 'background':
        case 'image':
          // Since we allow for AssetName, variable reference, and String URL here: Hold off on validating until toLambda().
          break;

        case 'displaySpeechAs':
          value = value.toString();
          if (!VALID_DISPLAY_SPEECH_AS_TYPES.includes(value)) {
            throw new lib.ParserError(location, `Unrecognized displaySpeechAs type '${value}' > expecting one of [${VALID_DISPLAY_SPEECH_AS_TYPES}]`)
          }
          // Also check if the text field the speech is supposed to be displayed as is supported by this template.
          // e.g. BodyTemplate6 doesn't have 'title'; BodyTemplate7 doesn't have 'primary|secondary|tertiaryText'.
          if (!supportedKeys.includes(value)) {
            throw new lib.ParserError(location, `Attribute ${key}'s type '${value}' not supported by ${template}.`);
          }
          break;

        default:
          break;
      }

      // 3) Our key and value were fine > add them.
      this.attributes[key] = value;
    }

    this.collectRequiredAPIs = function(apis) {
      apis['RENDER_TEMPLATE'] = true;
    }
  }
}
