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

aplParser = require('./lib/aplParser')
aplCommandParser = require('./lib/aplCommandParser')
aplHandler = require('./dist/handler')
aplValidators = require('./lib/aplValidators')

module.exports = function(options, lib) {
  return {
    compiler: {
      validators: {
        directives: {
          'Alexa.Presentation.APL.RenderDocument': aplValidators.renderDocumentDirective,
          'Alexa.Presentation.APL.ExecuteCommands': aplValidators.executeCommandsDirective
        },
        model: aplValidators.model,
        manifest: function(validator, skill) {
          // no manifest requirements
        }
      },
      validIntentNames: [
        'Alexa.Presentation.APL.UserEvent'
      ]
    },

    language: {
      statements: {
        aplcommand: {
          parser: `aplcommand
            = 'aplcommand' __ type:QuotedString {
              pushSay(location(), new lib.APLCommandParser(type));
            }
            / 'aplcommand' {
              pushSay(location(), new lib.APLCommandParser());
            }`
        },
        apl: {
          parser: `apl
            = 'apl' __ document:JsonFileName {
              pushSay(location(), new lib.APLParser(document));
            }
            / 'apl' __ document:VariableReference {
              pushSay(location(), new lib.APLParser(document));
            }
            / 'apl' {
              pushSay(location(), new lib.APLParser());
            }`
        }
      },
      testStatements: {},
      lib: {
        APLParser: aplParser(lib),
        APLCommandParser: aplCommandParser(lib)
      }
    },

    runtime: {
      apiName: 'APL',
      source: aplHandler
    }
  }
}
