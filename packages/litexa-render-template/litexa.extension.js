parser = require('./lib/renderTemplateParser')
handler = require('./dist/handler')
validators = require('./lib/renderTemplateValidators')

module.exports = function(options, lib) {
  return {
    compiler: {
      validators: {
        directives: {
          'Display.RenderTemplate': validators.directive
        },
        model: validators.model,
        manifest: function(validator, skill) {
          // no manifest requirements
        }
      },
      validIntentNames: [
        'Display.ElementSelected' // triggered by touching ListTemplate items
      ]
    },

    language: {
      statements: {
        /*
        Adds a new 'screen' statement to litexa, which can be shorthand called with the following attributes:
          screen [background] [title]
          screen [title] [background]
          screen [title]
          screen [background]
        */
        screen: {
          parser: `screen
            = 'screen' ___ image:ScreenImageReference __ ',' __ title:ScreenString {
              pushSay(location(), new lib.RenderTemplateParser(expression));
            }
            / 'screen' ___ title:ScreenString __ ',' __ image:ScreenImageReference {
              pushSay(location(), new lib.RenderTemplateParser(expression));
            }
            / 'screen' ___ title:ScreenString {
              pushSay(location(), new lib.RenderTemplateParser(title, undefined));
            }
            / 'screen' ___ image:ScreenImageReference {
              pushSay(location(), new lib.RenderTemplateParser(undefined, image));
            }
            / 'screen' {
              pushSay(location(), new lib.RenderTemplateParser());
            }
          `
        }
      },
      testStatements: {},
      lib: {
        RenderTemplateParser: parser(lib)
      }
    },

    runtime: {
      apiName: 'RenderTemplate',
      source: handler
    }
  }
}
