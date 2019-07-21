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

modelValidatorForGadgets = function({ validator, skill }) {
  const model = validator.jsonObject.languageModel;
  const requiredAPIs = {};
  skill.collectRequiredAPIs(requiredAPIs);

  if (requiredAPIs['GAME_ENGINE'] === true) {
    // intent structure:
    // { name: 'string', samples: ['arrayOfStrings'] }
    const modelIntents = model.intents;
    const requiredIntents = {
      'AMAZON.HelpIntent': false,
      'AMAZON.StopIntent': false
    }

    // 1. Check through all model intents, and mark each required intent we find.
    for (let intent of modelIntents) {
      if (requiredIntents.hasOwnProperty(intent.name))
        requiredIntents[intent.name] = true;
    }

    // 2. Check for all required intents we didn't find.
    const missingIntents = [];
    for (const [intent, found] of Object.entries(requiredIntents)) {
      if (!found) {
        missingIntents.push(intent);
      }
    }

    // 3. If required intents were missing in the language model, throw an indicative error.
    if (missingIntents.length > 0) {
      const err = [
        'When using the GAME_ENGINE interface, you must implement the following intents:\n',
        `${JSON.stringify(missingIntents)} `,
        "-> add at least one 'when' statement to handle each missing intent."
      ].join('').replace(/\n/g, '\n  '); // indent message with 2 spaces

      validator.errors.push(err);
    }
  }
}

module.exports = {
  modelValidatorForGadgets
}
