const {expect, should} = require('chai');
should();

const aplParser = require('../lib/aplParser');

const ParserError = class ParserError extends Error {
  constructor(location, message) {
    super();
    this.location = location;
    this.message = message;
    this.isParserError = true;
  }
};

const lib = {
  ParserError: ParserError
};

const parser = aplParser(lib);

describe('aplParser', function() {
  let parserInstance = new parser();

  describe('pushAttribute()', function() {
    parserInstance = undefined;

    beforeEach(function() {
      parserInstance = new parser();
    });

    it('rejects invalid attribute keys', function() {
      expect(function() {
        return parserInstance.pushAttribute(undefined, 'bogus', undefined);
      }).to.throw(ParserError, "Unknown attribute 'bogus' found in APL statement.");
    });

    it('rejects invalid attribute values', function() {
      expect(function() {
        return parserInstance.pushAttribute(undefined, 'token', {});
      }).to.throw(ParserError, "Attribute 'token' expects a String");
      expect(function() {
        return parserInstance.pushAttribute(undefined, 'document', 'string');
      }).to.throw(ParserError, "Attribute 'document' expects a value of type 'object'");
      expect(function() {
        return parserInstance.pushAttribute(undefined, 'data', 1);
      }).to.throw(ParserError, "Attribute 'data' expects a value of type 'object'");
      expect(function() {
        return parserInstance.pushAttribute(undefined, 'commands', true);
      }).to.throw(ParserError, "Attribute 'commands' expects a value of type 'object'");
    });

    it('adds valid attribute key|value pairs', function() {
      parserInstance.pushAttribute(undefined, 'token', 'NEW_TOKEN');
      expect(parserInstance.attributes.token).to.equal('NEW_TOKEN');

      const myDocument = {
        mainTemplate: {
          items: []
        }
      };
      parserInstance.pushAttribute(undefined, 'document', myDocument);
      expect(parserInstance.attributes.document).to.deep.equal(myDocument);

      const myData = {
        myDataObj: {
          type: 'object'
        }
      };
      parserInstance.pushAttribute(undefined, 'data', myData);
      expect(parserInstance.attributes.data).to.deep.equal(myData);

      const myCommand = {
        type: 'Idle'
      };
      parserInstance.pushAttribute(undefined, 'commands', myCommand);
      expect(parserInstance.attributes.commands).to.deep.equal(myCommand);
    });
  });
  describe('toLambda()', function() {
    beforeEach(function() {
      parserInstance = new parser();
    });

    it('adds a valid stringified context.apl object to output', function() {
      const srcAttributes = {
        document: {
          mainTemplate: {
            items: []
          }
        },
        data: {
          myDataObject: {
            type: 'object'
          }
        },
        commands: [
          {
            type: 'Idle'
          }
        ]
      };
      parserInstance.attributes = srcAttributes;

      const output = [];
      const indent = '  ';
      const options = {
        language: 'default'
      };
      parserInstance.toLambda(output, indent, options);

      const context = {
        apl: [],
        say: [],
        aplSpeechMarkers: []
      };

      // parserInstance.toLambda() stringifies an assignment to context.apl, and adds
      // it to output > let's make sure we can properly evaluate the code, and it yields
      // the expected context.apl object
      output.forEach(function(line) {
        eval(line);
      });
      expect(context.apl[0]).to.deep.equal(srcAttributes);
      expect(context.aplSpeechMarkers).to.deep.equal([0]);
    });
  });

  describe('collectRequiredAPIs()', function() {
    beforeEach(function() {
      parserInstance = new parser();
    });

    it('adds the ALEXA_PRESENTATION_APL api', function() {
      let apis = {};
      parserInstance.collectRequiredAPIs(apis);
      apis['ALEXA_PRESENTATION_APL'].should.be.true;
    });
  });
});
