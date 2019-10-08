/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const {isEmpty} = require('./aplUtils');
const {isValidDocument} = require('./aplDocumentHandler');
const {areValidCommands} = require('./aplCommandHandler');


module.exports = {
  model: function({ validator, skill }) {
    let requiredAPIs = {};
    skill.collectRequiredAPIs(requiredAPIs);

    if (requiredAPIs['ALEXA_PRESENTATION_APL'] !== true) {
      // Nothing to validate, if APL not required.
      return;
    }

    const requiredIntent = 'AMAZON.HelpIntent'; // this is the only intent required by APL
    const modelIntents = validator.jsonObject.languageModel.intents;

    for (intent of modelIntents) {
      if (intent.name === requiredIntent) {
        return;
      }
    }

    // Didn't find requiredIntent.
    const error = `When using the APL interface, you must implement the ${requiredIntent} (i.e. have at least one 'when' statement handling the intent).`;
    validator.errors.push(error);
  },

  renderDocumentDirective: function(validator) {
    let directive = validator.jsonObject;
    const docURL = 'https://developer.amazon.com/docs/alexa-presentation-language/apl-render-document-skill-directive.html';

    if (isEmpty(directive.token)) {
      const error = `${directive.type} requires a 'token' (${docURL}).`
      validator.errors.push(error);
    }

    if (isEmpty(directive.document)) {
      const error = `${directive.type} requires a 'document' (${docURL}).`
      validator.errors.push(error);
    } else if (!isValidDocument(directive.document)) {
      const error = `Invalid 'document' found in ${directive.type}.`
      validator.errors.push(error);
    }
  },

  executeCommandsDirective: function(validator) {
    let directive = validator.jsonObject;
    const docURL = 'https://developer.amazon.com/docs/alexa-presentation-language/apl-execute-command-directive.html';

    if (isEmpty(directive.token)) {
      const error = `${directive.type} requires a 'token' (${docURL}).`
      validator.errors.push(error);
    }

    if (isEmpty(directive.commands)) {
      const error = `${directive.type} requires 'commands' (${docURL}).`
      validator.errors.push(error);
    } else if (!areValidCommands(directive.commands)) {
      const error = `Invalid 'commands' found in ${directive.type}.`
      validator.errors.push(error);
    }
    return;
  }
}
