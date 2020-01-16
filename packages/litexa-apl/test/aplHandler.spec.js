/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const {assert, expect} = require('chai');
const {match, stub} = require('sinon');

const aplHandler = require('../lib/aplHandler');

const logger = console;

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
            'Alexa.Presentation.APL': {}
          }
        }
      }
    }
  }
};

// Simulating litexa object, which is otherwise available at runtime and required by path building functions.
global.litexa = {
  assetsRoot: '/mock/litexa/assets/root/'
}

describe('aplHandler', function() {
  let handler = undefined;
  let warnStub = undefined;

  beforeEach(function() {
    warnStub = stub(logger, 'warn');
    handler = aplHandler(context);
  });

  afterEach(function() {
    warnStub.restore();
  });

  describe('#isEnabled()', function() {
    it('should return true if the APL interface is declared', function() {
      expect(handler.userFacing.isEnabled()).to.be.true;
    });

    it('should return false if the context suggests APL is user disabled', function() {
      context.isUserEnabled = false;
      handler.userFacing.setUserEnabledCheck(function(context) {
        return context.isUserEnabled;
      });

      expect(handler.userFacing.isEnabled()).to.be.false;
    });
  });

  it('when sending document, interleaves speech with APL commands and empties context.say', function() {
    context.say = ['Speech1', 'Speech2', 'Speech3'];
    context.aplSpeechMarkers = [
      0, // fragment 1 to happen before speech[0]
      1  // fragment 2 to happen before speech[1]
    ];
    context.apl = [
      {
        document: {
          mainTemplate: {
            items: []
          }
        },
        commands: [
          {
            type: 'SpeakItem',
            componentId: 'Command 1'
          }
        ]
      },
      {
        commands: [
          {
            type: 'SpeakItem',
            componentId: 'Command 2'
          }
        ]
      }
    ];

    handler.events.afterStateMachine();
    const renderDirective = context.directives[0];
    const executeDirective = context.directives[1];

    const expectedMainTemplate = {
      items: [
        {
          type: 'Container',
          items: [
            {
              type: 'LitexaSpeechContainer'
            }
          ]
        }
      ]
    };
    expect(renderDirective.document.mainTemplate).to.deep.equal(expectedMainTemplate);

    const expectedExecuteDirective = {
      type: 'Alexa.Presentation.APL.ExecuteCommands',
      token: 'DEFAULT_TOKEN',
      commands: [
        {
          type: 'SpeakItem',
          componentId: 'Command 1' // before speech[0]
        },
        {
          type: 'SpeakItem',
          componentId: 'litexaID1' // command added for speech[0]
        },
        {
          type: 'SpeakItem',
          componentId: 'Command 2' // before speech[1]
        },
        {
          type: 'SpeakItem',
          componentId: 'litexaID2' // speech[1]
        },
        {
          type: 'SpeakItem',
          componentId: 'litexaID3' // speech[2]
        }
      ]
    };
    expect(executeDirective).to.deep.equal(expectedExecuteDirective);
    expect(context.say).to.be.empty;
  });

  it('when not sending document, leaves speech untouched to be handled by outputSpeech', function() {
    context.say = ['Speech1', 'Speech2', 'Speech3'];
    context.aplSpeechMarkers = [0, 1];
    context.apl = [
      {
        commands: [
          {
            type: 'SpeakItem',
            componentId: 'Command 1'
          }
        ]
      },
      {
        commands: [
          {
            type: 'SpeakItem',
            componentId: 'Command 2'
          }
        ]
      }
    ];
    handler.events.afterStateMachine();
    expect(context.say).to.deep.equal(['Speech1', 'Speech2', 'Speech3']);

    const expectedWarning = "say|soundEffects will play through outputSpeech BEFORE the APL command";
    assert(warnStub.calledWith(match(expectedWarning)), `Expected warning not logged: ${expectedWarning}`);
  });

  it('removes conflicting Display.RenderTemplate directives in beforeFinalResponse()', function() {
    let mockResponse = {
      directives: [
        {
          type: 'Alexa.Presentation.APL.ExecuteCommands'
        },
        {
          type: 'Display.RenderTemplate'
        }
      ]
    };
    handler.events.beforeFinalResponse(mockResponse);
    expect(mockResponse).to.deep.equal({
      directives: [
        {
          type: 'Alexa.Presentation.APL.ExecuteCommands'
        }
      ]
    });

    mockResponse = {
      directives: [
        {
          type: 'Display.RenderTemplate'
        },
        {
          type: 'Alexa.Presentation.APL.RenderDocument'
        },
        {
          type: 'AudioPlayer.Play'
        }
      ]
    };
    handler.events.beforeFinalResponse(mockResponse);
    expect(mockResponse).to.deep.equal({
      directives: [
        {
          type: 'Alexa.Presentation.APL.RenderDocument'
        },
        {
          type: 'AudioPlayer.Play'
        }
      ]
    });

    expect(warnStub.callCount).to.equal(2);
    const expectedWarning = "Found a Display.RenderTemplate directive alongside an APL directive!";
    assert(warnStub.alwaysCalledWith(match(expectedWarning)), `Expected warning not logged: ${expectedWarning}`);
  });
});
