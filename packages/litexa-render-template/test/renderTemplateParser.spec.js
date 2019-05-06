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

const { expect, should } = require('chai');
should();

const renderTemplateParser = require('../lib/renderTemplateParser');

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

const parser = renderTemplateParser(lib);

// Simulating litexa object, which is otherwise available at runtime and required by path building functions.
global.litexa = {
  assetsRoot: '/mock/litexa/assets/root/'
}

const mockSkill = {
  projectInfo: {
    languages: {
      default: {
        assets: {
          root: litexa.assetsRoot,
          files: ['mock.jpg']
        }
      }
    }
  }
};

const MockAsset = class MockAsset {
  constructor(name, type, skill = mockSkill) {
    this.name = name;
    this.type = type;
    this.skill = skill;
    this.isAssetName = true;
  }

  toString() {
    return `${this.name}.${this.type}`;
  }

  toURLFunction(lang) {
    return ` "${this.skill.projectInfo.languages.default.assets.root}${lang}/${this.toString()}" `;
  }
};

describe('RenderTemplateParser', function() {
  let parserInstance = undefined;

  describe('initializes correctly', function() {
    it('with arguments', function() {
      const mockBackground = new MockAsset('background', 'jpg');
      parserInstance = new parser('title', mockBackground);
      expect(parserInstance.attributes.template).to.equal('BodyTemplate1');
      expect(parserInstance.attributes.background).to.equal(mockBackground);
      expect(parserInstance.attributes.title).to.be.equal('title');
    });

    it('with no arguments', function() {
      parserInstance = new parser();
      expect(parserInstance.attributes.template).to.equal('BodyTemplate1');
      expect(parserInstance.attributes.background).to.be.undefined;
      expect(parserInstance.attributes.title).to.be.equal('');
    });
  });

  describe('pushAttribute()', function() {
    beforeEach(function() {
      parserInstance = new parser();
    });

    it('rejects invalid attribute keys', function() {
      expect(function() {
        return parserInstance.pushAttribute(void 0, 'backgroundImage', void 0);
      }).to.throw(ParserError, "use the equivalent 'background'");
      expect(function() {
        return parserInstance.pushAttribute(void 0, 'listItems', void 0);
      }).to.throw(ParserError, "use the equivalent 'list'");
      expect(function() {
        return parserInstance.pushAttribute(void 0, 'backButton', void 0);
      }).to.throw(ParserError, "BACK button is auto-HIDDEN");
      expect(function() {
        return parserInstance.pushAttribute(void 0, 'textContent', void 0);
      }).to.throw(ParserError, "use [primaryText, secondaryText, tertiaryText] instead");
      return expect(function() {
        return parserInstance.pushAttribute(void 0, 'bogus_key', void 0);
      }).to.throw(ParserError, "Unsupported attribute 'bogus_key' found");
    });

    it('rejects invalid attribute values', function() {
      expect(function() {
        return parserInstance.pushAttribute(void 0, 'template', 'BogusTemplateName');
      }).to.throw(ParserError, "Unrecognized template type");
      parserInstance.attributes.template = 'BodyTemplate2';
      expect(function() {
        return parserInstance.pushAttribute(void 0, 'displaySpeechAs', 'bogus_value');
      }).to.throw(ParserError, "Unrecognized displaySpeechAs type");
      parserInstance.attributes.template = 'BodyTemplate6';
      return expect(function() {
        return parserInstance.pushAttribute(void 0, 'displaySpeechAs', 'title');
      }).to.throw(ParserError, "'title' not supported by BodyTemplate6");
    });

    it('adds valid key|value pairs', function() {
      const mockImage = new MockAsset('background', 'jpg');
      parserInstance.pushAttribute(void 0, 'template', 'BodyTemplate2');
      parserInstance.pushAttribute(void 0, 'title', 'title');
      parserInstance.pushAttribute(void 0, 'primaryText', 'primary');
      parserInstance.pushAttribute(void 0, 'secondaryText', 'secondary');
      parserInstance.pushAttribute(void 0, 'tertiaryText', 'tertiary');
      parserInstance.pushAttribute(void 0, 'background', mockImage);
      parserInstance.pushAttribute(void 0, 'image', mockImage);
      parserInstance.pushAttribute(void 0, 'displaySpeechAs', 'title');
      parserInstance.pushAttribute(void 0, 'hint', 'hint');

      const expectedAttributes = {
        template: 'BodyTemplate2',
        title: 'title',
        primaryText: 'primary',
        secondaryText: 'secondary',
        tertiaryText: 'tertiary',
        background: mockImage,
        image: mockImage,
        displaySpeechAs: 'title',
        hint: 'hint'
      };
      expect(parserInstance.attributes).to.deep.equal(expectedAttributes);
    });

    it('adds list-specific key|value pairs', function() {
      const mockList = [
        {
          token: 1
        },
        {
          token: 2
        }
      ];
      parserInstance.pushAttribute(void 0, 'template', 'ListTemplate1');
      parserInstance.pushAttribute(void 0, 'list', mockList);
      expect(parserInstance.attributes.list).to.deep.equal(mockList);
    });
  });

  describe('toLambda()', function() {
    beforeEach(function() {
      parserInstance = new parser();
    });

    it('adds a valid stringified context.screen object to output', function() {
      const mockBackground = new MockAsset('background', 'jpg', mockSkill);
      const srcAttributes = {
        template: 'BodyTemplate2',
        title: 'title',
        primaryText: 'primary',
        secondaryText: 'secondary',
        tertiaryText: 'tertiary',
        background: mockBackground,
        image: 'image.jpg',
        displaySpeechAs: 'title',
        hint: 'hint'
      };
      parserInstance.attributes = srcAttributes;

      const output = [];
      const indent = '  ';
      const options = {
        language: 'default'
      };
      parserInstance.toLambda(output, indent, options);

      const context = {
        screen: {}
      };
      // parserInstance.toLambda() stringifies an assignment to context.screen, and adds
      // it to output > let's make sure we can properly evaluate the code, and it yields
      // the expected context.screen object
      eval(output[0]);

      const expectedScreen = {
        template: 'BodyTemplate2',
        title: 'title',
        primaryText: 'primary',
        secondaryText: 'secondary',
        tertiaryText: 'tertiary',
        background: `${litexa.assetsRoot}default/background.jpg`,
        image: `${litexa.assetsRoot}default/image.jpg`,
        displaySpeechAs: 'title',
        hint: 'hint'
      };

      expect(context.screen).to.deep.equal(expectedScreen);
    });
  });

  describe('collectRequiredAPIs()', function() {
    beforeEach(function() {
      parserInstance = new parser();
    });

    it('adds the RENDER_TEMPLATE api', function() {
      const apis = {};
      parserInstance.collectRequiredAPIs(apis);
      apis["RENDER_TEMPLATE"].should.be.true;
    });
  });
});
