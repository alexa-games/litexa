htmlHandler = require('./lib/htmlHandler');

HTMLStartClass = (lib) => {
  return class HTMLStart {
    constructor(url) {
      this.url = url;
      this.timeout = 120;
      this.initialData = null;
      this.transformers = null;
    }

    toLambda(output, indent, options) {
      let data = 'null';
      if ( this.initialData ) {
        if ( this.initialData.toLambda ) {
          data = this.initialData.toLambda(options);
        } else {
          data = JSON.stringify(this.initialData);
        }
      }
      let transformers = 'null';
      if ( this.transformers ) {
        if ( this.transformers.toLambda ) {
          transformers = this.transformers.toLambda(options);
        } else {
          transformers = JSON.stringify(this.transformers);
        }
      }
      output.push(`context.directives = context.directives || [];`);
      output.push(`context.directives.push(HTML.start('${this.url}', ${this.timeout}, ${data}, ${transformers}));`);
    }

    collectRequiredAPIs(apis) {
      apis['ALEXA_PRESENTATION_HTML'] = true;
    }

    pushAttribute(location, key, value) {
      switch (key) {
        case 'url':
          this.url = "" + value;
          break;
        case 'timeout':
          try {
            this.timeout = parseInt( value );
            if ( isNaN(this.timeout) ) {
              throw "Failed to parse a number"
            }
          } catch (err) {
            throw new lib.ParserError(location, "invalid value. This should be an integer, representing the number of seconds that the WebView will stay open without any user input.");
          }
          break;
        case 'initialData': 
          this.initialData = value;
          break;
        case 'transformers': 
          this.transformers = value;
          break;
        default:
          throw new lib.ParserError(location, `Unsupported attribute '${key}' found in HTML statement', expecting one of 'url', 'timeout', 'initialData', or 'transformers'`);
      }
    }
  }
}

class DisableHTMLTestStep {
  constructor(location, disable) {
    this.location = location;
    this.disable = disable;
  }

  run( {skill, lambda, context, resultCallback} ) {
    let blocks = skill.testBlockedInterfaces || [];
    blocks = blocks.filter( (b) => b !== 'Alexa.Presentation.HTML' );
    if ( this.disable ) {
      blocks.push( 'Alexa.Presentation.HTML' );
    }
    skill.testBlockedInterfaces = blocks;
    resultCallback(null, {});
  }

  report() {}
}

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

  return { compiler, language, runtime };
};
