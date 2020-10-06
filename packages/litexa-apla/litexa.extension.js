/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const runtimeSource = require('./runtime.js');


module.exports = (options, lib) => {
  const compiler = {
    validEventNames: [],
    validators: {
      manifest: () => {},
      model: () => {},
      directives: {
        'Alexa.Presentation.APLA.RenderDocument': () => {}
      }
    }
  };

  const language = {
    statements: {
      BeginAPLABlock: {
        parser: `
          BeginAPLABlock = 'APLABlock' ___ name:QuotedString? { pushSay(location(), new lib.APLABlock(name)); }`
      }
    },
    testStatements: {},
    lib: {
      APLABlock: APLABlock(lib)
    },
    sayTags: {}
  };

  const runtime = {
    apiName: 'APLA',
    source: runtimeSource
  };

  const additionalAssetExtensions = [ '.ogg', '.m4a', '.mp4' ];

  return { compiler, language, runtime, additionalAssetExtensions };
};


APLABlock = (lib) => {
  return class APLABlock {
    constructor(name) {
      this.name = name;
      this.background = null;
      this.delay = 0;
    }

    toLambda(output, indent, options) {
      let args = {
        background: this.background,
        delay: this.delay
      }
      output.push(`${indent}APLA.insertBlock(\`${this.name}\`, ${JSON.stringify(args)});`);
    }

    pushAttribute(location, key, value) {
      switch (key) {
        case 'background':
          this.background = "" + value;
          break;
        case 'delay':
          try {
            this.delay = parseInt( value );
            if ( isNaN(this.delay) ) {
              throw "Failed to parse a number"
            }
          } catch (err) {
            throw new lib.ParserError(location, "invalid value. This should be an integer, representing the number of milliseconds that the group's contents should be delayed by.");
          }
          break;
        default:
          throw new lib.ParserError(location, `Unsupported attribute '${key}' found in APLGroup statement', expecting one of 'background' or 'delay'`);
      }
    }
  }
}