const { HTMLStartClass } = require('./HTMLStart');
const { DisableHTMLTestStep } = require('./DisableHTMLTestStep');
const htmlHandler = require('./lib/htmlHandler');

module.exports = (options, lib) => {
  const compiler = {
    validEventNames: ['Alexa.Presentation.HTML.Message'],
    validators: {
      manifest: () => {},
      model: () => {},
      directives: {
        'Alexa.Presentation.HTML.Start': () => {},
        'Alexa.Presentation.HTML.HandleMessage': () => {}
      }
    }
  };

  const language = {
    statements: {
      SendHTMLStart: {
        parser: `SendHTMLStart = 'HTML' ___ url:QuotedString? { pushSay(location(), new lib.HTMLStart(url)); }`
      }
    },
    testStatements: {
      DisableHTML: {
        parser: `DisableHTML = 'DisableHTML' ___ value:('true'/'false') { 
          currentTest().pushTestStep(new lib.DisableHTMLTestStep(location(), value === 'true')); }`
      }
    },
    lib: {
      HTMLStart: HTMLStartClass(lib),
      DisableHTMLTestStep: DisableHTMLTestStep
    },
    sayTags: {
      mark: {
        process: (obj) => {
          obj.tag = 'mark';
          obj.attributes = { name: obj.content };
          obj.content = null;
        }
      } 
    }
  };

  const runtime = {
    apiName: 'HTML',
    source: htmlHandler
  };

  const additionalAssetExtensions = [
    '.html', '.js', '.map', '.css', '.ico',
    '.gif', '.webm', '.webp',
    '.ogg', '.m4a', '.mp4',
    '.glb', '.gltf',
    '.ttf', '.otf', '.woff'
  ];

  return { compiler, language, runtime, additionalAssetExtensions };
};
