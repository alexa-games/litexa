const {isEmpty} = require('./aplUtils');

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
    for (let k of Object.keys(this.srcObj)) {
      let v = this.srcObj[k];

      // Let's detect our value's type, and evaluate it if necessary.
      if (!isEmpty(v)) {
        if (typeof(v.toExpression) === 'function') {
          this.destObj[k] = v.toExpression(this.options);
        } else if (v.isAssetName) {
          this.destObj[k] = v.toURLFunction(this.options.language);
        } else if (typeof(v) === 'string') {
          this.destObj[k] = `'${v}'`;
        } else if (typeof v === 'object') {
          this.destObj[k] = JSON.stringify(v);
        } else {
          this.destObj[k] = v;
        }
      }
    }
  },

  stringifyObject: function() {
    const lines = Object.keys(this.destObj).map((key) => {
      return `${this.indent}  ${key}: ${this.destObj[key]}`
    });

    return `{\n  ${lines.join(',\n  ')}\n  }`;
  }
}
