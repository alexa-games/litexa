const {expect, should} = require('chai');
should();

const aplCommandParser = require('../lib/aplCommandParser');

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

const parser = aplCommandParser(lib);

describe('aplCommandParser', function() {
  let parserInstance = undefined;

  describe('pushAttribute()', function() {
    beforeEach(function() {
      parserInstance = new parser();
    });

    it('validates command type', function() {
      expect(function() {
        return parserInstance.pushAttribute(undefined, 'type', 'bogus');
      }).to.throw(ParserError, "Invalid command type 'bogus' found");

      parserInstance.pushAttribute(undefined, 'type', 'Idle');
      expect(parserInstance.attributes.commands['type']).to.equal('Idle');
    });

    it('validates command parameter', function() {
      parserInstance.pushAttribute(undefined, 'type', 'Idle');
      expect(function() {
        return parserInstance.pushAttribute(undefined, 'value', 1);
      }).to.throw(ParserError, "Invalid command parameter 'value' found");

      parserInstance.pushAttribute(undefined, 'delay', 2000);
      expect(parserInstance.attributes.commands['delay']).to.equal(2000);
    });
  });

  describe('toLambda()', function() {
    beforeEach(function() {
      parserInstance = new parser();
    });

    it('adds a valid stringified context.apl object to output', function() {
      const myCommand = {
        type: 'Idle',
        delay: 1000
      };
      parserInstance.attributes.commands = myCommand;

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

      expect(context.apl[0].commands).to.deep.equal(myCommand);
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
