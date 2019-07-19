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

const {assert, expect} = require('chai');
const {match, spy, stub, useFakeTimers} = require('sinon');

const helpers = require('../lib/aplHandlerHelpers');

const logger = console;

// Simulating litexa object, which is otherwise available at runtime and required by path building functions.
global.litexa = {
  assetsRoot: '/mock/litexa/assets/root/'
};

const myTestData = {
  language: 'de',
  curSpeechIndex: 0
};

describe('aplHandlerHelpers', function() {
  let errorStub = undefined;
  let speakSpy = undefined;

  it('runs init()', function() {
    helpers.init({
      myData: myTestData
    });
    expect(helpers.myData).to.deep.equal(myTestData);
    expect(helpers.token).to.equal('DEFAULT_TOKEN');
    expect(helpers.language).to.equal('de');
  });

  it('adds a non-empty token', function() {
    helpers.addToken('');
    expect(helpers.token).to.equal('DEFAULT_TOKEN');
    helpers.addToken('NEW_TOKEN');
    expect(helpers.token).to.equal('NEW_TOKEN');
  });

  it('adds a wrapper document', function() {
    const document = {
      document: {},
      data: {},
      datasources: {}
    };
    helpers.addDocument(document);
  });

  describe('addSpeech()', function() {
    beforeEach(function() {
      errorStub = stub(logger, 'error');
      speakSpy = spy(helpers, 'addSpeakItem');
    });

    afterEach(function() {
      errorStub.restore();
      speakSpy.restore();
    });

    it('ignores empty and non-string speech', function() {
      helpers.addSpeech('');
      expect(speakSpy.callCount).to.equal(0);
      helpers.addSpeech({
        string: 'string'
      });
      const expectedError = "Received non-string speech of type 'object'";
      assert(errorStub.calledWith(match(expectedError)), `Expected error not logged: ${expectedError}`);
    });

    it('adds regular speech', function() {
      helpers.addSpeech('testing speech');
      assert(speakSpy.calledOnceWithExactly({
        speech: 'testing speech',
        suffix: '0',
        isURL: false
      }));
    });

    it('adds speech that is an audio tag', function() {
      helpers.addSpeech("<audio src='http://url'/>");
      expect(speakSpy.callCount).to.equal(1);
      expect(speakSpy.firstCall.args[0]).to.deep.equal({
        speech: 'http://url',
        suffix: '0',
        isURL: true
      });
    });

    it('adds speech mixed with an audio tag', function() {
      helpers.addSpeech("testing speech with before<audio src='http://url'/> and after ");
      expect(speakSpy.callCount).to.equal(3);
      expect(speakSpy.firstCall.args[0]).to.deep.equal({
        speech: 'testing speech with before',
        suffix: '0a',
        isURL: false
      });
      expect(speakSpy.secondCall.args[0]).to.deep.equal({
        speech: 'http://url',
        suffix: '0b',
        isURL: true
      });
      expect(speakSpy.thirdCall.args[0]).to.deep.equal({
        speech: 'and after',
        suffix: '0c',
        isURL: false
      });
    });

    it('adds multiple audio tags with no speech', function() {
      helpers.addSpeech("<audio src='http://url1'/><audio src='http://url2'/>");
      expect(speakSpy.callCount).to.equal(2);
      expect(speakSpy.firstCall.args[0]).to.deep.equal({
        speech: 'http://url1',
        suffix: '0a',
        isURL: true
      });
      expect(speakSpy.secondCall.args[0]).to.deep.equal({
        speech: 'http://url2',
        suffix: '0b',
        isURL: true
      });
    });
  });

  describe('directives', function() {
    beforeEach(function() {
      errorStub = stub(logger, 'error');
      helpers.init({
        myData: myTestData
      });
    });

    afterEach(function() {
      errorStub.restore();
    });

    it('returns undefined directives if document/commands invalid', function() {
      expect(helpers.createRenderDocumentDirective()).to.be.undefined;
      expect(helpers.createExecuteCommandsDirective()).to.be.undefined;
    });

    it('creates expected RenderDocument directive structure, and replaces local file references', function() {
      const myDocument = {
        mainTemplate: {
          items: [
            {
              url: 'assets://file1.png',
              source: 'assets://file2.png'
            }
          ]
        }
      };
      const myData = {
        myObject: {
          type: 'object',
          url: 'assets://file1.png',
          source: 'assets://file2.png'
        }
      };
      helpers.addDocument(myDocument);
      helpers.addData(myData);

      const directive = helpers.createRenderDocumentDirective();
      const expectedDirective = {
        type: 'Alexa.Presentation.APL.RenderDocument',
        token: 'DEFAULT_TOKEN',
        document: {
          type: 'APL',
          version: '1.0',
          mainTemplate: {
            items: [
              {
                url: `${litexa.assetsRoot}${myTestData.language}/file1.png`,
                source: `${litexa.assetsRoot}${myTestData.language}/file2.png`
              }
            ]
          }
        },
        datasources: {
          myObject: {
            type: 'object',
            url: `${litexa.assetsRoot}${myTestData.language}/file1.png`,
            source: `${litexa.assetsRoot}${myTestData.language}/file2.png`
          }
        }
      };
      expect(directive).to.deep.equal(expectedDirective);
    });

    it('creates expected ExecuteCommands directive structure', function() {
      const myCommands = [
        {
          type: 'Idle',
          delay: 1000
        }
      ];
      helpers.addToken('TEST_TOKEN');
      helpers.addCommands(myCommands);

      const directive = helpers.createExecuteCommandsDirective();
      const expectedDirective = {
        type: 'Alexa.Presentation.APL.ExecuteCommands',
        token: 'TEST_TOKEN',
        commands: myCommands
      };
      expect(directive).to.deep.equal(expectedDirective);
    });
  });
});

describe('sanitizeFileReferences', function() {
  const now = new Date();
  let clock = undefined;

  beforeEach(function() {
    helpers.init({
      myData: myTestData
    });
    helpers.myData.shouldUniqueURLs = 'true';

    // Let's fake the time, since uniquifyAssetUrls() uses Date().getTime() stamps.
    clock = useFakeTimers(now.getTime());
  });

  this.afterEach(function() {
    clock.restore();
  });

  it('properly sanitizes source URLs and local file references', function() {
    const mockDocument = {
      "type": "APL",
      "version": "1.1",
      "theme": "dark",
      "import": [],
      "mainTemplate": {
        "parameters": [
          "payload"
        ],
        "items": [
          {
            "type": "Container",
            "width": "100vw",
            "height": "100vh",
            "items": [
              {
                "type": "Image",
                "id": "mockImage1",
                "source": "https://s3.us-east-1.amazonaws.com/filePath.jpg"
              },
              {
                "type": "Container",
                "items": [
                  {
                    "type": "Image",
                    "id": "mockImage2",
                    "source": "https://s3.us-east-1.amazonaws.com/filePath.png"
                  },
                  {
                    "type": "Image",
                    "id": "mockImage3",
                    "source": "assets://myFile.bmp"
                  }
                ]
              }
            ]
          }
        ]
      }
    }

    const expectedSanitizedDocument = {
      "type": "APL",
      "version": "1.1",
      "theme": "dark",
      "import": [],
      "mainTemplate": {
        "parameters": [
          "payload"
        ],
        "items": [
          {
            "type": "Container",
            "width": "100vw",
            "height": "100vh",
            "items": [
              {
                "type": "Image",
                "id": "mockImage1",
                "source": `https://s3.us-east-1.amazonaws.com/filePath.jpg#${clock.now}`
              },
              {
                "type": "Container",
                "items": [
                  {
                    "type": "Image",
                    "id": "mockImage2",
                    "source": `https://s3.us-east-1.amazonaws.com/filePath.png#${clock.now}`
                  },
                  {
                    "type": "Image",
                    "id": "mockImage3",
                    "source": `/mock/litexa/assets/root/de/myFile.bmp#${clock.now}`
                  }
                ]
              }
            ]
          }
        ]
      }
    }

    expect(helpers.sanitizeAssetReferences(mockDocument)).to.deep.equal(expectedSanitizedDocument);
  });
});
