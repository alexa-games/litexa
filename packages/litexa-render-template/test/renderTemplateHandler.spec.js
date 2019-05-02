const { expect } = require('chai');

const renderTemplateHandler = require('../lib/renderTemplateHandler.js');

const context = {
  say: [],
  directives: [],
  screen: {},
  language: 'default',
  event: {
    context: {
      System: {
        device: {
          supportedInterfaces: {
            Display: {}
          }
        }
      }
    }
  }
};

process.env.shouldUniqueURLs = 'false';

const handler = renderTemplateHandler(context);

describe('RenderTemplateHandler', function() {
  beforeEach(function() {
    context.screen = [];
    context.directives = [];
  });

  it('returns correct value for userFacing.isEnabled()', function() {
    context.event.context.System.device.supportedInterfaces = {};
    expect(handler.userFacing.isEnabled()).to.be.false;

    context.event.context.System.device.supportedInterfaces = {
      Display: {}
    };
    expect(handler.userFacing.isEnabled()).to.be.true;
  });

  it('generates a valid body render template directive', function() {
    context.screen = {
      template: 'BodyTemplate2',
      background: 'http://background.jpg',
      primaryText: 'primary',
      secondaryText: 'secondary',
      tertiaryText: 'tertiary',
      image: 'http://earth.jpg',
      displaySpeechAs: 'title'
    };

    expectedRenderDirective = {
      template: {
        type: context.screen.template,
        backButton: 'HIDDEN',
        title: '',
        backgroundImage: {
          sources: [
            {
              url: context.screen.background
            }
          ]
        },
        textContent: {
          primaryText: {
            text: context.screen.primaryText,
            type: 'RichText'
          },
          secondaryText: {
            text: context.screen.secondaryText,
            type: 'RichText'
          },
          tertiaryText: {
            text: context.screen.tertiaryText,
            type: 'RichText'
          }
        },
        image: {
          sources: [
            {
              url: context.screen.image
            }
          ]
        }
      },
      type: 'Display.RenderTemplate'
    };
    handler.events.afterStateMachine();
    expect(context.directives).to.have.deep.members([expectedRenderDirective]);
  });

  it('generates a valid list render template directive', function() {
    context.screen = {
      template: 'ListTemplate1',
      title: 'title',
      background: 'http://background.jpg',
      list: [
        {
          token: '1',
          primaryText: '1st primary'
        },
        {
          token: '2',
          primaryText: '2nd primary'
        }
      ]
    };

    handler.events.afterStateMachine();

    const expectedRenderDirective = {
      template: {
        type: context.screen.template,
        backButton: 'HIDDEN',
        title: context.screen.title,
        backgroundImage: {
          sources: [
            {
              url: context.screen.background
            }
          ]
        },
        listItems: [
          {
            token: context.screen.list[0].token,
            textContent: {
              primaryText: {
                text: context.screen.list[0].primaryText,
                type: 'RichText'
              }
            }
          },
          {
            token: context.screen.list[1].token,
            textContent: {
              primaryText: {
                text: context.screen.list[1].primaryText,
                type: 'RichText'
              }
            }
          }
        ]
      },
      type: 'Display.RenderTemplate'
    };
    expect(context.directives).to.have.deep.members([expectedRenderDirective]);
  });

  it("it doesn't generate a render template directive if RenderTemplate not enabled", function() {
    context.event.context.System.device.supportedInterfaces = {};
    context.screen = {
      template: 'BodyTemplate1',
      title: 'title'
    };
    handler.events.afterStateMachine();
    expect(context.directives).to.deep.equal([]);
    context.event.context.System.device.supportedInterfaces = {
      Display: {}
    };
  });

  it('generates a valid hint directive', function() {
    context.screen = {
      hint: 'Hint Text'
    };

    handler.events.afterStateMachine();

    const expectedHintDirective = {
      type: 'Hint',
      hint: {
        type: 'PlainText',
        text: context.screen.hint
      }
    };
    expect(context.directives).to.be.an('array').that.deep.includes(expectedHintDirective);
  });
});
