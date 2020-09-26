module.exports = (context) => {
  const contextHasHTML = () => {
    const interfaces =
      context &&
      context.event &&
      context.event.context &&
      context.event.context.System &&
      context.event.context.System.device &&
      context.event.context.System.device.supportedInterfaces;
    return interfaces && interfaces.hasOwnProperty('Alexa.Presentation.HTML');
  };

  let userFacing = {};
  let isEnabled = true;

  userFacing.setEnabled = (enabled) => isEnabled = enabled;
  userFacing.isHTMLPresent = () => contextHasHTML() && isEnabled;
  
  userFacing.mark = (str) => {
    if (!contextHasHTML()) { return; }
    context.say.push(`<mark name='${str}'/>`);
  }

  userFacing.start = (url, timeout, initialData, transformers) => {
    if (!contextHasHTML()) { return null; }
    timeout = timeout || 480;
    initialData = initialData || undefined;
    transformers = transformers || undefined;
    let absoluteUrl = url;
    if ( typeof(absoluteUrl) !== 'string' ) {
      throw new Error("HTML.start can only take a string as the url argument, got " + url);
    }
    
    if ( absoluteUrl.indexOf('http://') >= 0 ) {
      throw new Error("The Alexa Web API will only work with https URLs, failed on " + url);
    }
    
    if ( absoluteUrl.indexOf('https://') < 0 ) {
      absoluteUrl = litexa.assetsRoot + litexa.language + '/' + url;
    }

    let directive = {
      type: 'Alexa.Presentation.HTML.Start',
      request: {
        uri: absoluteUrl
      },
      configuration: {
        timeoutInSeconds: timeout
      },
      data: initialData,
      transformers: transformers
    };
    return directive;
  }

  return {
    userFacing: userFacing,
    events: {}
  };
};
