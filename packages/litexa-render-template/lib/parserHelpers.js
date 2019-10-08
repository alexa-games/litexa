/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
