const {assert, expect} = require('chai');
const {match, stub} = require('sinon');

const documentHandler = require('../lib/aplDocumentHandler');

const logger = console;

const custPrefix = 'litexa';
const custSuffix = 'suffix';

documentHandler.init({
  prefix: custPrefix
});

describe('aplDocumentHandler', function() {
  const errorPrefix = "This expected error wasn't logged: ";
  const warnPrefix = "This expected warning wasn't logged: ";
  const speechContainerId = 'LitexaSpeechContainer';
  const url = 'http://myUrl';

  let errorSpy = undefined;
  let warnSpy = undefined;

  describe('itemToItems()', function() {
    beforeEach(function() {
      errorSpy = stub(logger, 'error');
      documentHandler.document = {};
    });

    afterEach(function() {
      errorSpy.restore();
    });

    it('converts mainTemplate item object to items array', function() {
      const mainTemplate = {
        item: {
          type: 'Text',
          text: 'content'
        }
      };
      const expectedMainTemplate = {
        items: [
          {
            type: 'Text',
            text: 'content'
          }
        ]
      };
      documentHandler.itemToItems(mainTemplate);
      expect(mainTemplate).to.deep.equal(expectedMainTemplate);
    });

    it('pushes mainTemplate item array to items', function() {
      const mainTemplate = {
        item: [
          {
            type: 'Text',
            text: 'content1'
          },
          {
            type: 'Text',
            text: 'content2'
          }
        ]
      };
      const expectedMainTemplate = {
        items: [
          {
            type: 'Text',
            text: 'content1'
          },
          {
            type: 'Text',
            text: 'content2'
          }
        ]
      };
      documentHandler.itemToItems(mainTemplate);
      expect(mainTemplate).to.deep.equal(expectedMainTemplate);
    });

    it('rejects invalid mainTemplate item', function() {
      const mainTemplate = {
        item: 'string'
      };
      const expectedError = `Found non-array and non-object 'item' of type '${mainTemplate.item}'`;
      documentHandler.itemToItems(mainTemplate);
      assert(errorSpy.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
    });
  });

  describe('addDocument()', function() {
    beforeEach(function() {
      errorSpy = stub(logger, 'error');
      warnSpy = stub(logger, 'warn');
      documentHandler.document = {};
    });

    afterEach(function() {
      errorSpy.restore();
      warnSpy.restore();
    });

    it('addDocument() rejects empty or non-object document', function() {
      documentHandler.addDocument({});
      expect(documentHandler.document).to.be.empty;

      const document = 'string';
      documentHandler.addDocument(document);
      const expectedError = `Tried adding non-object document of type '${typeof document}'`;
      assert(errorSpy.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
    });

    it('addDocument() replaces mainTemplate', function() {
      const doc1 = {
        mainTemplate: {
          item: {
            type: "text",
            item: "item1"
          }
        }
      };
      const doc2 = {
        mainTemplate: {
          items: {
            type: "text",
            item: "item2"
          }
        }
      };
      documentHandler.addDocument(doc1);
      documentHandler.addDocument(doc2);

      const expectedWarning = "aplDocumentHandler found two mainTemplates";
      assert(warnSpy.calledWith(match(expectedWarning)), `${warnPrefix}${expectedWarning}`);

      const expectedDoc = {
        mainTemplate: {
          items: {
            type: "text",
            item: "item2"
          }
        }
      };
      expect(documentHandler.document).to.deep.equal(expectedDoc);
    });
  });

  describe('addSpeechContainer()', function() {
    beforeEach(function() {
      errorSpy = stub(logger, 'error');
      documentHandler.document = {};
    });

    afterEach(function() {
      errorSpy.restore();
    });

    it('adds non-URL speech to an empty document', function() {
      documentHandler.addSpeechContainer({
        speech: 'speech',
        suffix: custSuffix
      });
      const expectedLayouts = {
        [`${speechContainerId}`]: {
          item: {
            type: 'Container',
            items: [
              {
                type: 'Text',
                id: `${custPrefix}ID${custSuffix}`,
                speech: `\${payload.${custPrefix}SpeechObject${custSuffix}.properties.${custPrefix}Speech${custSuffix}}`
              }
            ]
          }
        }
      };
      const expectedItems = [
        {
          type: 'Container',
          items: [
            {
              type: speechContainerId
            }
          ]
        }
      ];
      expect(documentHandler.document.layouts).to.deep.equal(expectedLayouts);
      expect(documentHandler.document.mainTemplate.items).to.deep.equal(expectedItems);
    });

    it('adds a URL speech to an empty document', function() {
      documentHandler.addSpeechContainer({
        speech: url,
        suffix: custSuffix,
        isURL: true
      });
      const expectedLayouts = {
        [`${speechContainerId}`]: {
          item: {
            type: 'Container',
            items: [
              {
                type: 'Text',
                id: `${custPrefix}ID${custSuffix}`,
                speech: url
              }
            ]
          }
        }
      };
      const expectedItems = [
        {
          type: 'Container',
          items: [
            {
              type: `${speechContainerId}`
            }
          ]
        }
      ];
      expect(documentHandler.document.layouts).to.deep.equal(expectedLayouts);
      expect(documentHandler.document.mainTemplate.items).to.deep.equal(expectedItems);
    });

    it('merges with existing document layouts and mainTemplate', function() {
      const document = {
        layouts: {
          Header: {
            parameters: [],
            items: []
          }
        },
        mainTemplate: {
          item: {
            type: 'Text',
            text: 'content'
          }
        }
      };
      documentHandler.addDocument(document);
      documentHandler.addSpeechContainer({
        speech: url,
        suffix: custSuffix,
        isURL: true
      });

      const expectedLayouts = {
        Header: {
          parameters: [],
          items: []
        },
        [`${speechContainerId}`]: {
          item: {
            type: 'Container',
            items: [
              {
                type: 'Text',
                id: `${custPrefix}ID${custSuffix}`,
                speech: url
              }
            ]
          }
        }
      };
      const expectedItems = [
        {
          type: 'Container',
          items: [
            {
              type: 'Text',
              text: 'content'
            },
            {
              type: `${speechContainerId}`
            }
          ]
        }
      ];
      expect(documentHandler.document.layouts).to.deep.equal(expectedLayouts);
      expect(documentHandler.document.mainTemplate.items).to.deep.equal(expectedItems);
      expect(documentHandler.document.mainTemplate.item).to.be.undefined;
    });

    it('merges with existing speech container', function() {
      const document = {
        layouts: {
          [`${speechContainerId}`]: {
            item: {
              type: 'Container',
              items: [
                {
                  type: 'Text',
                  id: `${custPrefix}ID${custSuffix}`,
                  speech: url
                }
              ]
            }
          }
        },
        mainTemplate: {
          items: [
            {
              type: 'Container',
              items: [
                {
                  type: `${speechContainerId}`
                }
              ]
            }
          ]
        }
      };
      documentHandler.addDocument(document);
      documentHandler.addSpeechContainer({
        speech: url,
        suffix: `${custSuffix}2`,
        isURL: true
      });

      const expectedLayouts = {
        [`${speechContainerId}`]: {
          item: {
            type: 'Container',
            items: [
              {
                type: 'Text',
                id: `${custPrefix}ID${custSuffix}`,
                speech: url
              },
              {
                type: 'Text',
                id: `${custPrefix}ID${custSuffix}2`,
                speech: url
              }
            ]
          }
        }
      };
      const expectedItems = [
        {
          type: 'Container',
          items: [
            {
              type: `${speechContainerId}`
            }
          ]
        }
      ];
      expect(documentHandler.document.layouts).to.deep.equal(expectedLayouts);
      expect(documentHandler.document.mainTemplate.items).to.deep.equal(expectedItems);
    });
  });

  describe('isValidDocument()', function() {
    beforeEach(function() {
      errorSpy = stub(logger, 'error');
      warnSpy = stub(logger, 'warn');
      documentHandler.document = {};
    });

    afterEach(function() {
      errorSpy.restore();
      warnSpy.restore();
    });

    it('rejects empty document and missing or empty mainTemplate', function() {
      expect(documentHandler.isValidDocument({})).to.be.false;

      let document = {
        type: 'APL',
        version: '1.0'
      };
      documentHandler.isValidDocument(document);
      let expectedError = "Missing required attribute 'mainTemplate'";
      assert(errorSpy.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);

      document = {
        mainTemplate: {}
      };
      expectedError = "Missing required attribute 'mainTemplate'";
      documentHandler.isValidDocument(document);
      assert(errorSpy.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
    });

    it('adds missing version and type', function() {
      const document = {
        mainTemplate: {
          items: []
        }
      };
      const expectedDocument = {
        type: 'APL',
        version: '1.0',
        mainTemplate: document.mainTemplate
      };
      documentHandler.addDocument(document);
      expect(documentHandler.isValidDocument()).to.be.true;
      expect(documentHandler.document).to.deep.equal(expectedDocument);
    });

    it('warns about unknown attribute', function() {
      const document = {
        bogusAttribute: {},
        mainTemplate: {
          items: []
        }
      };
      documentHandler.isValidDocument(document);
      const expectedWarning = "Unsupported attribute 'bogusAttribute' found in document.";
      assert(warnSpy.calledWith(match(expectedWarning)), `${warnPrefix}${expectedWarning}`);
    });
  });
});
