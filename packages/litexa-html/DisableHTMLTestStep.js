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

exports.DisableHTMLTestStep = DisableHTMLTestStep