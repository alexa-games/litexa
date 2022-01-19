function abbreviateSpeech( text ) {
  // do a little abbreviate to make scanning easier
  text = text.replace(/<voice\s+name\s*=\s*["']([^"']+)["']\s*>/gi, (a, b) => `<${b}>`);
  text = text.replace(/<amazon:domain\s+name\s*=\s*["']([^"']+)["']\s*>/gi, (a, b) => `<${b}>`);
  text = text.replace(/<\/voice>/gi, '');
  text = text.replace(/<\/amazon:domain>/gi, '');
  return text;
}

function appendItemsRecursive( result, root, padding ) {
  // recursive function to print out an easily scannable
  // representation of the APLA JSON doc, so that humans 
  // can read the output log and look for content errors
  let subPadding = padding + "| ";
 
  // append a description of this node
  switch( root.type ) {
    case 'Silence':
      result.push( `${padding}Silence: ${root.duration}`);
      break;
    case 'Event': 
      result.push( `${padding}Event: ${root.name}`);
      break;
    case 'Audio': 
      result.push( `${padding}Audio: ${root.source}`);
      break;
    case 'Speech':
      let speech = root.content.replace(/<\/?speak>/g, '');
      speech = abbreviateSpeech(speech);
      result.push( `${padding}"${speech}"`);
      break;
    default: 
      // we can ignore the root, commonly just an untyped container
      if ( padding != "" ) {
        result.push( `${padding}${root.type || "NOTYPE"}`);
      } else {
        subPadding = " ";
      }
      break;
  }
    
  // if it has children, indent a little and then walk through
  // each of those, getting each to print themselves out
  if ( root.items ) {
    for ( let item of root.items ) {
      appendItemsRecursive( result, item, subPadding );
    }
  }
}

module.exports.formatter = function( directive ) {
  
  let document = directive.document;
  let mainTemplate = document.mainTemplate || {};
 
  // lead with a heading in the printed output
  let result = [ '<< APLA Document >>' ];

  // walk the whole document from the root
  appendItemsRecursive( result, mainTemplate, "" );

  // return an array of lines to append to the test log output
  return result;
}