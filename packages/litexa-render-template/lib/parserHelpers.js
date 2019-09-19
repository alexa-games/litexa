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

const {isEmpty} = require('./renderTemplateUtils')

exports.ObjectStringBuilder = {
  parseAndStringify: function(args) {
    this.init(args);
    this.parseAttributes();
    return this.stringifyObject();
  },

  init: function(args) {
    this.options = args.options;
    this.indent = args.indent || '';
    this.srcObj = args.attributes || {};
    this.destObj = {};
  },

  parseAttributes: function() {
    let relativeURLs = {};
    for (let k of Object.keys(this.srcObj)) {
      let v = this.srcObj[k];

      if (!isEmpty(v)) {
        if (typeof(v.toExpression) === 'function') {
          relativeURLs[k] = true;
          this.destObj[k] = v.toExpression(this.options);
        } else if (v.isAssetName) {
          const assetName = v.toURLFunction(this.options.language);
          this.destObj[k] = (assetName.indexOf('http') < 0) ? assetName : `'${assetName}'`;
        } else if (typeof(v) === 'string') {
          relativeURLs[k] = true;
          this.destObj[k] = `'${v}'`;
        } else {
          this.destObj[k] = v;
        }
      }
    }
    this.addRelativeImageURLs(relativeURLs);
  },

  addRelativeImageURLs: function(relativeURLs) {
    for (let k in relativeURLs) {
      if (k === 'background' || k === 'image') {
        if (this.destObj[k].indexOf('http') < 0) {
          this.destObj[k] = `litexa.assetsRoot + '${this.options.language}/' + ${this.destObj[k]}`;
        }
      }
    }
  },

  stringifyObject: function() {
    const lines = Object.keys(this.destObj).map((key) => {
      return `${this.indent}  ${key}: ${this.destObj[key]}`
    });

    return `{\n  ${lines.join(',\n  ')}\n${this.indent}  }`;
  }
}
