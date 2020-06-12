/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

// Script to cache the current coverage report. This can be used to persist the reports in a
// .nyc_output_combined directory, which is then utilized by npm run coverage:report.
const path = require('path');
const mkdirp = require('mkdirp');
const move = require('move-concurrently')
const fs = require('fs');

let src = path.join(__dirname, '.nyc_output');
let dst = path.join(__dirname, '.nyc_output_combined');

let promises = [];
let moveDir = (leaf) => {
  let things = fs.readdirSync(path.join(src,leaf));
  mkdirp.sync(path.join(dst,leaf));
  for ( let i=0; i<things.length; ++i ) {
    let thing = things[i];
    if ( thing[0] == '.' ) { continue; }
    let stat = fs.lstatSync(path.join(src,leaf,thing));
    if ( stat.isFile() ) {
      promises.push( move( path.join(src,leaf,thing), path.join(dst,leaf,thing) ) );
    } else if ( stat.isDirectory() ) {
      moveDir(path.join(leaf,thing));
    }
  }
}
moveDir('');

Promise.all(promises).then( () => {
  console.log("completed coverage file move");
}).catch( (err) => {
  console.error(`failed to move coverage files: ${err}`);
  process.exit(-1);
});