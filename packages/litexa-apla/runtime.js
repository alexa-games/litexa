/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

module.exports = (context) => {

  // known list of APLA component types, used as a filter blow to prevent
  //  including any say objects that aren't valid APLA, which may have been
  //  inserted by other systems 
  const KnownAPLATypes = [ 'Audio', 'Mixer', 'Selector', 'Sequencer', 'Silence', 'Speech' ];
  
  // simple constructors for the various components
  function APLADirective() {
    let mainItems = [];

    return [ {
      type: "Alexa.Presentation.APLA.RenderDocument",
      token: "request:" + context.request.requestId,
      datasources: {},
      document: {
        type: "APLA",
        version: "0.91",
        mainTemplate: {
          items: [
            {
              type: "Sequencer",
              items: mainItems
            }
          ]
        }
      }
    }, mainItems ];
  }

  function APLASequencer( id ) {
    return {
      id: id,
      type: "Sequencer",
      items: []
    }
  }

  function APLAMixer( id ) {
    return {
      id: id,
      type: "Mixer",
      items: []
    }
  }

  function APLASilence( durationInMilliseconds ) {
    return {
      type: "Silence",
      duration: durationInMilliseconds
    }
  }

  function APLSpeechSSML( id, content ) {
    return {
      id: id,
      type: "Speech",
      content: `<speak>${content}</speak>`,
      contentType: "SSML"
    }
  }

  function APLAudio( id, url ) {
    let absoluteUrl = '' + url;
    if ( absoluteUrl.indexOf('http://') >= 0 ) {
      throw new Error("The APLA Audio component will only work with https URLs, failed on " + url);
    }

    if ( absoluteUrl.indexOf('https://') < 0 ) {
      absoluteUrl = litexa.assetsRoot + litexa.language + '/' + url;
    }

    return {
      id: id,
      type: "Audio",
      source: absoluteUrl
    }
  }


  function splitAudioTags( line ) {
    let test = /<audio\s+src=['"]([^'"]+)['"]\s*\/>/g;
    let match = test.exec( line );
    if ( !match ) {
      return [ line ];
    }
    let before = line.substr( 0, match.index ).trim();
    let after = line.substr( match.index + match[0].length ).trim();
    let inside = match[1].trim();
    let result = [];
    if ( before ) { result = result.concat( splitAudioTags(before) ) }
    if ( inside ) { result.push( { audio:inside } ) }
    if ( after ) { result = result.concat( splitAudioTags(after) ) }
    return result;
  }

  // the object that will appear as APLA at runtime
  // note: this is a new object every invocation, and has
  // the current invocation's context object bound in a closure.
  const userFacing = {
    APLADirective,
    APLASequencer,
    APLSpeechSSML,
    APLAudio,
    splitAudioTags
  };

  userFacing.accumulator = [];
  userFacing.componentAccumulator = [];
  userFacing.disableAPLA = false;

  userFacing.pushComponent = ( component ) => {
    context.say.push( component );
  }

  // insert a marker that Litexa "say" material after this point
  // belongs in a named block for later reference
  userFacing.insertBlock = ( name, options ) => {
    let block = {
      sayIndex: context.say.length,
      name: name
    };
    Object.assign( block, options || {} );
    userFacing.accumulator.push( block );
  }

  let afterStateMachine = () => {
    
    const disableAPLA = userFacing.disableAPLA;
    if (disableAPLA) {
      // if we have to bail on APLA processing, then we have to
      // dump anything that we pushed into the say array that isn't
      // a standard speech string
      let filteredSay = [];
      for ( let say of context.say ) {
        if ( (typeof(say) == "string") ) {
          filteredSay.push( say );
        }
      }
      context.say = filteredSay;
      return;
    }
    
    let accumulator = userFacing.accumulator;

    // If the response is plain text to speech, then we
    // don't need to bother converting it into an APL-A document.
    // The presence of any named blocks means we're not simple.
    let simple = accumulator.length == 0;

    // To get the hi-def audio support, any audio present also
    // kicks us over to APL-A.
    let audioTester = /\<audio/g;
    for ( let say of context.say ) {
      if ( (typeof(say) == "string") ) {
        if ( say.match( audioTester ) ) {
          simple = false;
        }
      } else {
        simple = false;
      }
    }
    
    if ( simple ) {
      // no modifications to make here, we'll let the say content
      // go down the usual pipe and end up in outputSpeech
      return;
    }

    // split up the say content into named blocks, beginning with
    // an implicit one called "UNNAMED" that captures anything
    // before the first named block.
    let lastBlock = { name: "UNNAMED", say: [], sayIndex: 0 };
    let blocks = [];
    blocks.push( lastBlock );
    for ( let nextBlock of accumulator ) {
      // move the say content up until this point into the last block
      lastBlock.say = context.say.slice( lastBlock.sayIndex, nextBlock.sayIndex );
      lastBlock = nextBlock
      blocks.push( nextBlock );
    }
    // flush the remaining contents into the last block
    lastBlock.say = context.say.slice( lastBlock.sayIndex );
    // drop any blocks that didn't end up with content
    blocks = blocks.filter( b => b.say.length > 0 );

    // Within a block we don't care about preserving individual text say
    // items, so we can merge them into single speech blocks
    for ( let block of blocks ) {
      let mergeds = [];
      for ( let say of block.say ) {
        if ( typeof(say) == 'string' ) {
          if ( typeof( mergeds[mergeds.length-1]) == 'string' ) {
            mergeds[mergeds.length-1] += ' ' + say;
          } else {
            mergeds.push(say);
          }
        } else {
          mergeds.push( say );
        }
      }
    }

    // we've taken responsibility for audio being not SSML compatible format
    // so we need to split out any audio references and turn them into
    // APL-A components
    for ( let block of blocks ) {
      let oldSays = block.say;
      block.say = [];
      for ( let say of oldSays ) {
        block.say = block.say.concat( splitAudioTags(say) );
      }
    }

    // prepare the APL-A directive that'll carry the APL-A doc
    let [ directive, mainItems ] = APLADirective();
    
    let pushSayAsComponent = (list, name, item) => {
      if ( item.audio ) {
        list.push( APLAudio( name, item.audio ) );
      } else if ( item.silence ) {
        list.push( APLASilence( item.silence ) );
      } else if ( typeof(item) == 'object') {
        // support building components manually in the skill code
        if ( KnownAPLATypes.indexOf(item.type) >= 0 ) {
          list.push(item);
        }
      } else {
       list.push( APLSpeechSSML( name, item ) );
      }
    }

    // convert each block into APL-A content
    for ( let block of blocks ) {
      let container = mainItems;
      let name = block.name;

      if ( block.background ) {
        // if this block has background music, setup a mixer to parallelize
        // playback between that and the say content
        let mixer = APLAMixer( block.name );
        mainItems.push( mixer );
        mixer.items.push( APLAudio( undefined, block.background ) );
        container = mixer.items;
        name = undefined;
      }

      if ( block.delay ) {
        // if the contents need to be delayed to make room for the start
        // of the background audio, we'll use a silence to space it out
        block.say.unshift( { silence: block.delay } );
      }

      if ( block.say.length == 1 ) {
        // blocks with just a single thing can just be the thing
        pushSayAsComponent( container, name, block.say[0] );
      } else {
        // blocks with multiple bits of content are wrapped in a sequence
        let sequence = APLASequencer( name );
        container.push(sequence);
        for ( let say of block.say ) {
          pushSayAsComponent( sequence.items, undefined, say );
        }
      }
    }

    // splice in the directive
    context.directives = context.directives || [];
    context.directives.push( directive );

    // steal the say content from Litexa, removing it from outputSpeech
    context.say = [];
  }

  return {
    userFacing: userFacing,
    events: {
      afterStateMachine
    }
  };
}