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

const {isEmpty} = require('./aplUtils');
const {isValidDocument} = require('./aplDocumentHandler');
const {areValidCommands} = require('./aplCommandHandler');


module.exports = {
  model: function(validator, manifest, skill) {
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
