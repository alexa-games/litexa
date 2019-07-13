/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const {isEmpty} = require('./renderTemplateUtils');
const {TEMPLATE_INFO, VALID_TEMPLATE_TYPES} = require('./renderTemplateInfo');

module.exports = {
  model: function({ validator, skill }) {
    let requiredAPIs = {};
    skill.collectRequiredAPIs(requiredAPIs);

    if (requiredAPIs['RENDER_TEMPLATE'] !== true) {
      // Nothing to validate, if RenderTemplate not required.
      return;
    }

    let requiredIntents = {
      'AMAZON.HelpIntent': true,
      'AMAZON.MoreIntent': true,
      'AMAZON.NavigateHomeIntent': true,
      'AMAZON.NavigateSettingsIntent': true,
      'AMAZON.NextIntent': true,
      'AMAZON.PageDownIntent': true,
      'AMAZON.PageUpIntent': true,
      'AMAZON.PreviousIntent': true,
      'AMAZON.ScrollDownIntent': true,
      'AMAZON.ScrollLeftIntent': true,
      'AMAZON.ScrollRightIntent': true,
      'AMAZON.ScrollUpIntent': true,
      'AMAZON.StopIntent': true
    }

    const modelIntents = validator.jsonObject.languageModel.intents;

    for (let intent of modelIntents) {
      if (requiredIntents[intent.name]) {
        requiredIntents[intent.name] = false;
      }
    }

    let missing = [];

    for (let key of Object.keys(requiredIntents)) {
      if (requiredIntents[key]) {
        missing.push(key);
      }
    }

    if (missing.length > 0) {
      const error = `When using the RenderTemplate interface, you must implement the intents [${missing.join(', ')}] (i.e. have at least one 'when' statement handling each intent).`;
      validator.errors.push(error);
    }
  },

  directive: function(validator) {
    let directive = validator.jsonObject;
    const docURL = 'https://developer.amazon.com/docs/custom-skills/display-interface-reference.html';

    if (isEmpty(directive.template)) {
      const error = `${directive.type} requires a 'template' (${docURL}).`
      validator.errors.push(error);
    } else if (isEmpty(directive.template.type)) {
      const error = `${directive.type}'s 'template' requires a 'type' (${docURL}).`
      validator.errors.push(error);
    } else if (!VALID_TEMPLATE_TYPES.includes(directive.template.type)) {
      const error = `${directive.type}'s template has invalid type '${directive.template.type}'.`
      validator.errors.push(error);
    } else {
      const supportedKeys = TEMPLATE_INFO[directive.template.type].keys;
      const specialKeys = ['type', 'title', 'backButton', 'backgroundImage', 'textContent', 'listItems']; // these keys either have shorthand equivalents or overrides

      for (let key of Object.keys(directive.template)) {
        if (specialKeys.includes(key)) {
          continue;
        }
        if (!supportedKeys.includes(key)) {
          const error = `${directive.type}'s template '${directive.template.type}' has invalid key '${key}'.`
          validator.errors.push(error);
        }
        // @TODO: Could eventually also add type/integrity checking for the attribute values here.
      }
    }
  }
}
