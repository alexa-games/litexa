const {assert, expect} = require('chai');
const {match, stub} = require('sinon');

const helpers = require('../lib/handlerHelpers');

const logger = console;

cloneOf = function(obj) {
  return JSON.parse(JSON.stringify(obj));
};

describe('RenderTemplate HandlerHelpers', function() {
  let errorSpy = undefined;
  const errorPrefix = "This expected error wasn't logged: ";

  const args = {
    myData: {
      shouldUniqueURLs: false
    },
    template: {
      type: 'BodyTemplate1',
      backButton: 'HIDDEN',
      title: ''
    }
  };

  describe('init()', function() {
    it('initializes with no arguments', function() {
      helpers.init();
      expect(helpers.myData).to.be.empty;
      expect(helpers.template).to.be.empty;
    });

    it('initializes with myData and template', function() {
      helpers.init(cloneOf(args));
      expect(helpers.myData).to.deep.equal(args.myData);
      expect(helpers.template).to.deep.equal(args.template);
    });
  });

  describe('addHTMLTags()', function() {
    it('adds HTML tags for implicit newlines', function() {
      const src = "a\nmultiline\nstring";
      const dest = helpers.addHTMLTags(src);
      expect(dest).to.equal('a<br/>multiline<br/>string');
    });

    it('adds HTML tags for explicit newlines', function() {
      const src = "a\nmultiline\nstring";
      const dest = helpers.addHTMLTags(src);
      expect(dest).to.equal('a<br/>multiline<br/>string');
    });

    it('adds HTML tags for ampersands', function() {
      const src = "string with &";
      const dest = helpers.addHTMLTags(src);
      expect(dest).to.equal('string with &amp;');
    });

    it('adds HTML tags for both newlines and ampersands', function() {
      const src = "string with implicit\nand explicit\nand the symbol &";
      const dest = helpers.addHTMLTags(src);
      expect(dest).to.equal('string with implicit<br/>and explicit<br/>and the symbol &amp;');
    });
  });

  describe('addText()', function() {
    beforeEach(function() {
      helpers.init(cloneOf(args));
    });

    it('ignores empty text', function() {
      helpers.addText('', 'primaryText');
      expect(helpers.template.textContent).to.be.undefined;
    });

    it('adds primary, secondary, and tertiary text', function() {
      const srcAttributes = {
        primaryText: 'primary',
        secondaryText: 'secondary',
        tertiaryText: 'tertiary'
      };
      const expectedTextContent = {
        primaryText: {
          text: srcAttributes.primaryText,
          type: 'RichText'
        },
        secondaryText: {
          text: srcAttributes.secondaryText,
          type: 'RichText'
        },
        tertiaryText: {
          text: srcAttributes.tertiaryText,
          type: 'RichText'
        }
      };
      Object.keys(srcAttributes).forEach(function (key) {
        const val = srcAttributes[key];
        helpers.addText(val, key, helpers.template);
      })
      expect(helpers.template.textContent).to.deep.equal(expectedTextContent);
    });
  });

  describe('uniqueURL()', function() {
    const src = 'http://www.amazon.com';

    beforeEach(function() {
      helpers.init(cloneOf(args));
    });

    it('handles shouldUniqueURLs = false', function() {
      helpers.myData.shouldUniqueURLs = 'false';
      expect(helpers.uniqueURL(src)).does.equal(src);
    });

    it('handles shouldUniqueURLs = true', function() {
      helpers.myData.shouldUniqueURLs = 'true';
      const newURL = helpers.uniqueURL(src);
      expect(newURL).does.not.equal(src);
      expect(newURL.substr(0, src.length)).to.equal(src);
    });
  });

  describe('addImage()', function() {
    beforeEach(function() {
      helpers.init(cloneOf(args));
    });

    it('rejects a blank source', function() {
      helpers.addImage({}, 'image');
      expect(helpers.template.image).to.be.undefined;
    });

    it('adds an image', function() {
      const expectedImage = {
        sources: [
          {
            url: 'http://myImageUrl'
          }
        ]
      };
      ['image', 'backgroundImage'].forEach(function (type) {
        helpers.addImage(expectedImage.sources[0].url, type);
        expect(helpers.template[type]).to.deep.equal(expectedImage);
      });
    });
  });

  describe('createListItem()', function() {
    beforeEach(function() {
      helpers.init(cloneOf(args));
      errorSpy = stub(logger, 'error');
    });

    afterEach(function() {
      errorSpy.restore();
    });

    it('rejects empty source item', function() {
      helpers.createListItem({});
      const expectedError = "Empty srcItem > ignoring list item.";
      assert(errorSpy.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
    });

    it('creates a valid list item', function() {
      const srcItem = {
        primaryText: 'primary',
        secondaryText: 'secondary &',
        tertiaryText: 'tertiary \n',
        image: 'http://my.image.url',
        token: 'My Token'
      };
      const destItem = helpers.createListItem(srcItem);
      const expectedItem = {
        textContent: {
          primaryText: {
            text: srcItem.primaryText,
            type: 'RichText'
          },
          secondaryText: {
            text: 'secondary &amp;',
            type: 'RichText'
          },
          tertiaryText: {
            text: 'tertiary <br/>',
            type: 'RichText'
          }
        },
        image: {
          sources: [
            {
              url: 'http://my.image.url'
            }
          ]
        },
        token: 'My Token'
      };
      expect(destItem).to.deep.equal(expectedItem);
    });

    it('rejects tertiaryText for ListTemplate2', function() {
      helpers.template.type = 'ListTemplate2';
      const srcItem = {
        tertiaryText: 'tertiary'
      };
      const destItem = helpers.createListItem(srcItem);
      const expectedError = "Attribute 'tertiaryText' not supported by 'ListTemplate2'";
      assert(errorSpy.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
      expect(destItem).to.be.empty;
    });

    it('rejects unknown attribute', function() {
      const srcItem = {
        bogus: 'attribute'
      };
      const destItem = helpers.createListItem(srcItem);
      const expectedError = "Unsupported attribute 'bogus' found";
      assert(errorSpy.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
      expect(destItem).to.be.empty;
    });
  });

  describe('addList()', function() {
    beforeEach(function() {
      helpers.init(cloneOf(args));
      errorSpy = stub(logger, 'error');
    });

    afterEach(function() {
      errorSpy.restore();
    });

    it('adds a valid list', function() {
      const srcList = [
        {
          token: '1',
          primaryText: 'primary'
        },
        {
          token: '2',
          image: 'http://my.image.url'
        },
        {
          token: '3',
          secondaryText: 'secondary',
          tertiaryText: 'tertiary'
        }
      ];
      const destListItems = [
        {
          token: srcList[0].token,
          textContent: {
            primaryText: {
              text: srcList[0].primaryText,
              type: 'RichText'
            }
          }
        },
        {
          token: srcList[1].token,
          image: {
            sources: [
              {
                url: srcList[1].image
              }
            ]
          }
        },
        {
          token: srcList[2].token,
          textContent: {
            secondaryText: {
              text: srcList[2].secondaryText,
              type: 'RichText'
            },
            tertiaryText: {
              text: srcList[2].tertiaryText,
              type: 'RichText'
            }
          }
        }
      ];
      helpers.addList(srcList);
      expect(helpers.template.listItems).to.deep.equal(destListItems);
    });

    it('rejects a non-array list', function() {
      const srcList = {
        item: {}
      };
      helpers.addList(srcList);
      const expectedError = "srcList was not an array > ignoring list.";
      assert(errorSpy.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
    });

    it('rejects a invalid items', function() {
      const srcList = [
        {
          bogus: 'item'
        }
      ];
      helpers.addList(srcList);
      const expectedError = "no valid attributes found > ignoring list item.";
      // 1st error = createListItem ignoring the invalid attribute.
      // 2nd error = addList ignoring the empty item.
      assert(errorSpy.secondCall.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
    });
  });

  describe('stripLineSSML()', function() {
    helpers.init(cloneOf(args));

    it('strips out SSML tags', function() {
      const line = "<say-as interpret-as='interjection'>something</say-as>";
      expect(helpers.stripLineSSML(line)).to.equal('something');
    });

    it('strips out escaped SSML tags', function() {
      const line = "\<say-as interpret-as='ordinal'>1\</say-as>";
      expect(helpers.stripLineSSML(line)).to.equal('1');
    });
  });

  describe('stripSpeechSSML()', function() {
    helpers.init(cloneOf(args));

    it('strips every lines\' SSML tags', function() {
      const speech = ["line with <say-as interpret-as='interjection'>something</say-as> said-as", "line with <break time=\'100ms\'/> a break", "line with <audio src='http://link_to_audio.com/> audio"];
      const strippedSpeech = ['line with something said-as', 'line with a break', 'line with audio'];
      expect(helpers.stripSpeechSSML(speech)).to.deep.equal(strippedSpeech);
    });
  });

  describe('addDisplaySpeechAs()', function() {
    const speech = ["line <say-as interpret-as='interjection'>one</say-as>", "line two"];

    beforeEach(function() {
      helpers.init(cloneOf(args));
    });

    it('adds speech to empty title', function() {
      helpers.addDisplaySpeechAs(speech, 'title');
      expect(helpers.template.title).to.equal('line one line two');
    });

    it('adds speech to existing title', function() {
      helpers.template.title = 'Title';
      helpers.addDisplaySpeechAs(speech, 'title');
      expect(helpers.template.title).to.equal('Title line one line two');
    });

    it('adds speech to empty body attributes', function() {
      helpers.addDisplaySpeechAs(speech, 'primaryText');
      helpers.addDisplaySpeechAs(speech, 'secondaryText');
      helpers.addDisplaySpeechAs(speech, 'tertiaryText');

      const expectedTextContent = {
        primaryText: {
          text: 'line one<br/><br/>line two',
          type: 'RichText'
        },
        secondaryText: {
          text: 'line one<br/><br/>line two',
          type: 'RichText'
        },
        tertiaryText: {
          text: 'line one<br/><br/>line two',
          type: 'RichText'
        }
      };
      expect(helpers.template.textContent).to.deep.equal(expectedTextContent);
    });

    it('adds speech to existing body attributes', function() {
      helpers.template.textContent = {
        primaryText: {
          text: 'primary',
          type: 'RichText'
        },
        secondaryText: {
          text: 'secondary',
          type: 'RichText'
        },
        tertiaryText: {
          text: 'tertiary',
          type: 'RichText'
        }
      };

      helpers.addDisplaySpeechAs(speech, 'primaryText');
      helpers.addDisplaySpeechAs(speech, 'secondaryText');
      helpers.addDisplaySpeechAs(speech, 'tertiaryText');

      const expectedTextContent = {
        primaryText: {
          text: 'primary line one<br/><br/>line two',
          type: 'RichText'
        },
        secondaryText: {
          text: 'secondary line one<br/><br/>line two',
          type: 'RichText'
        },
        tertiaryText: {
          text: 'tertiary line one<br/><br/>line two',
          type: 'RichText'
        }
      };
      expect(helpers.template.textContent).to.deep.equal(expectedTextContent);
    });
  });
});
