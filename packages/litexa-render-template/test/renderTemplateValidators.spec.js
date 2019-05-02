const { expect } = require('chai');
const { stub } = require('sinon');

const renderValidators = require('../lib/renderTemplateValidators');

const logger = console;

describe('renderTemplateValidators', function() {
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
    const requiredIntents = [
      'AMAZON.HelpIntent',
      'AMAZON.MoreIntent',
      'AMAZON.NavigateHomeIntent',
      'AMAZON.NavigateSettingsIntent',
      'AMAZON.NextIntent',
      'AMAZON.PageDownIntent',
      'AMAZON.PageUpIntent',
      'AMAZON.PreviousIntent',
      'AMAZON.ScrollDownIntent',
      'AMAZON.ScrollLeftIntent',
      'AMAZON.ScrollRightIntent',
      'AMAZON.ScrollUpIntent',
      'AMAZON.StopIntent'
    ];

    const mockSkill = {
      collectRequiredAPIs: function(obj) {
        return obj['RENDER_TEMPLATE'] = true;
      }
    };

    validator.jsonObject = {
      languageModel: {
        intents: []
      }
    };

    renderValidators.model(validator, undefined, mockSkill);
    expect(validator.errors).to.have.members([
      `When using the RenderTemplate interface, you must implement the intents [${requiredIntents.join(', ')}] (i.e. have at least one 'when' statement handling each intent).`
    ]);

    validator.errors = [];
    requiredIntents.forEach(function(intent) {
      validator.jsonObject.languageModel.intents.push({
        name: intent,
        samples: []
      });
    });
    renderValidators.model(validator, undefined, mockSkill);
    expect(validator.errors).to.deep.equal([]);
  });

  it('rejects invalid directives', function() {
    const docURL = 'https://developer.amazon.com/docs/custom-skills/display-interface-reference.html';
    const directive = {
      type: 'Display.RenderTemplate'
    };

    validator.jsonObject = directive;
    renderValidators.directive(validator);
    expect(validator.errors).to.have.members([`${directive.type} requires a 'template' (${docURL}).`]);

    validator.errors = [];
    directive.template = {
      backButton: 'HIDDEN'
    };
    renderValidators.directive(validator);
    expect(validator.errors).to.have.members([`${directive.type}'s 'template' requires a 'type' (${docURL}).`]);

    validator.errors = [];
    directive.template.type = 'BogusTemplate';
    renderValidators.directive(validator);
    expect(validator.errors).to.have.members([`${directive.type}'s template has invalid type '${directive.template.type}'.`]);

    validator.errors = [];
    directive.template.type = 'BodyTemplate2';
    directive.template.bogusKey = 'bogusValue';
    renderValidators.directive(validator);
    expect(validator.errors).to.have.members([`${directive.type}'s template '${directive.template.type}' has invalid key 'bogusKey'.`]);
  });

  it('adds a valid directive', function() {
    const directive = {
      type: 'Display.RenderTemplate',
      template: {
        type: 'BodyTemplate2',
        backButton: 'HIDDEN',
        title: 'title',
        textContent: {
          primaryText: {
            text: 'primary',
            type: 'RichText'
          }
        }
      }
    };
    validator.jsonObject = directive;
    renderValidators.directive(validator);
    expect(validator.errors).to.deep.equal([]);
  });
});
