exports.HTMLStartClass = (lib) => {
  return class HTMLStart {
    constructor(url) {
      this.url = url;
      this.timeout = 120;
      this.initialData = null;
      this.transformers = null;
      this.breakURLCaching = false;
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
      let url = this.url;
      if ( this.breakURLCaching ) {
        url = `('${this.url}?=' + Math.floor(Math.random()*9999999))`;
      } else {
        url = `'${this.url}'`;
      }
      output.push(`${indent}if( HTML.isHTMLPresent() ) {`);
      output.push(`${indent}  context.directives = context.directives || [];`);
      output.push(`${indent}  let d = HTML.start(${url}, ${this.timeout}, ${data}, ${transformers});`)
      output.push(`${indent}  if (d) { context.directives.push(d); }`);
      output.push(`${indent}}`);
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
        case 'breakURLCaching':
          if ( typeof(value) === 'string' ) { value = value === 'true' }
          else { value = !!value; }
          this.breakURLCaching = value;
          break;
        default:
          throw new lib.ParserError(location, `Unsupported attribute '${key}' found in HTML statement', expecting one of 'url', 'breakURLCaching', 'timeout', 'initialData', or 'transformers'`);
      }
    }
  }
}