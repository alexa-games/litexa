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

const {expect} = require('chai');
const {stub} = require('sinon');

const aplValidators = require('../lib/aplValidators');

const logger = console;

describe('aplValidators', function() {
  let errorSpy = undefined;
  const validator = {};

  beforeEach(function() {
    errorSpy = stub(logger, 'error');
    validator.jsonObject = {};
    validator.errors = [];
  });

  afterEach(function() {
    errorSpy.restore();
  });

  it('validates model', function() {
    validator.jsonObject = {
      languageModel: {
        intents: []
      }
    };
    const mockSkill = {
      collectRequiredAPIs: function(obj) {
        return obj['ALEXA_PRESENTATION_APL'] = true;
      }
    };
    aplValidators.model(validator, undefined, mockSkill);
    expect(validator.errors).to.have.members([`When using the APL interface, you must implement the AMAZON.HelpIntent (i.e. have at least one 'when' statement handling the intent).`]);

    validator.errors = [];
    validator.jsonObject.languageModel.intents = [
      {
        name: 'AMAZON.HelpIntent',
        samples: []
      }
    ];
    aplValidators.model(validator, undefined, mockSkill);
    expect(validator.errors).to.deep.equal([]);
  });

  it('validates RenderDocument directive', function() {
    const directive = {
      type: 'Alexa.Presentation.APL.RenderDocument',
      token: 'DEFAULT_TOKEN',
      document: {
        mainTemplate: {
          items: []
        }
      }
    };
    validator.jsonObject = directive;
    aplValidators.renderDocumentDirective(validator);
    expect(validator.errors).to.deep.equal([]);
  });

  it('rejects RenderDocument with missing properties', function() {
    const docURL = 'https://developer.amazon.com/docs/alexa-presentation-language/apl-render-document-skill-directive.html';
    const directive = {
      type: 'Alexa.Presentation.APL.RenderDocument'
    };
    validator.jsonObject = directive;
    aplValidators.renderDocumentDirective(validator);
    expect(validator.errors).to.have.members([`${directive.type} requires a 'token' (${docURL}).`, `${directive.type} requires a 'document' (${docURL}).`]);
  });

  it('rejects RenderDocument with invalid document', function() {
    const directive = {
      type: 'Alexa.Presentation.APL.RenderDocument',
      token: 'DEFAULT_TOKEN',
      document: {
        mainTemplate: {}
      }
    };
    validator.jsonObject = directive;
    aplValidators.renderDocumentDirective(validator);
    expect(validator.errors).to.have.members([`Invalid 'document' found in ${directive.type}.`]);
  });

  it('validates ExecuteCommands directive', function() {
    const directive = {
      type: 'Alexa.Presentation.APL.ExecuteCommands',
      token: 'DEFAULT_TOKEN',
      commands: [
        {
          type: 'Idle'
        }
      ]
    };
    validator.jsonObject = directive;
    aplValidators.executeCommandsDirective(validator);
    expect(validator.errors).to.deep.equal([]);
  });

  it('rejects ExecuteCommands with missing properties', function() {
    const docURL = 'https://developer.amazon.com/docs/alexa-presentation-language/apl-execute-command-directive.html';
    const directive = {
      type: 'Alexa.Presentation.APL.ExecuteCommands'
    };
    validator.jsonObject = directive;
    aplValidators.executeCommandsDirective(validator);
    expect(validator.errors).to.have.members([`${directive.type} requires a 'token' (${docURL}).`, `${directive.type} requires 'commands' (${docURL}).`]);
  });

  it('rejects ExecuteCommands with invalid commands', function() {
    const docURL = 'https://developer.amazon.com/docs/alexa-presentation-language/apl-execute-command-directive.html';
    const directive = {
      type: 'Alexa.Presentation.APL.ExecuteCommands',
      token: 'TOKEN',
      commands: [
        {
          type: 'Bogus'
        }
      ]
    };
    validator.jsonObject = directive;
    aplValidators.executeCommandsDirective(validator);
    expect(validator.errors).to.have.members([`Invalid 'commands' found in ${directive.type}.`]);

    validator.errors = [];
    directive.commands = [
      {
        type: 'Idle',
        bogus: 1
      }
    ];
    aplValidators.executeCommandsDirective(validator);
    expect(validator.errors).to.have.members([`Invalid 'commands' found in ${directive.type}.`]);
  });
});
