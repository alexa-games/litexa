/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const runtimeSource = require('../runtime');
const assert = require('assert');

describe( 'splits audio tags correctly', () => {
  let APLA = runtimeSource({}).userFacing;

  it( 'finds a single tag', () => {
    let result = APLA.splitAudioTags( "<audio src='test://default/stub.mp3'/>" );
    assert.equal( result.length, 1 );
    assert.equal( result[0].audio, 'test://default/stub.mp3' );
  });

  it( 'finds content before and after a single tag', () => {
    let result = APLA.splitAudioTags( "hello <audio src='test://default/stub.mp3'/> how are you?" );
    assert.equal( result.length, 3 );
    assert.equal( result[0], 'hello' );
    assert.equal( result[1].audio, 'test://default/stub.mp3' );
    assert.equal( result[2], 'how are you?' );
  });

  it ( 'finds successive tags', () => {
    let result = APLA.splitAudioTags( "hello <audio src='https://default/1.mp3'/><audio src='https://default/2.mp3'/> are you?" );
    assert.equal( result.length, 4 );
    assert.equal( result[0], 'hello' );
    assert.equal( result[1].audio, 'https://default/1.mp3' );
    assert.equal( result[2].audio, 'https://default/2.mp3' );
    assert.equal( result[3], 'are you?' );
  })

  it ( 'finds successive tags with contents in between', () => {
    let result = APLA.splitAudioTags( "hello <audio src='https://default/1.mp3'/> what's that <audio src='https://default/2.mp3'/> are you?" );
    assert.equal( result.length, 5 );
    assert.equal( result[0], 'hello' );
    assert.equal( result[1].audio, 'https://default/1.mp3' );
    assert.equal( result[2], "what's that" );
    assert.equal( result[3].audio, 'https://default/2.mp3' );
    assert.equal( result[4], 'are you?' );
  })

});