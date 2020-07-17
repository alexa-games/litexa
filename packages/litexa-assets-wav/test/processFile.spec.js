require('coffeescript/register');
const {processFile} = require('../litexa.extension.coffee');
const {expect} = require('chai');
const path = require('path');
const mkdirp = require('mkdirp');
const rimraf = require('rimraf');
const fs = require('fs');

const nullLogger = {
  log: (msg) => {}
};

describe( 'processFile creates an MP3, given a wav file', () => {
  const filename = "doorbell.wav";
  source = path.normalize( path.join( __dirname, '..', filename ) );

  targetRoot = path.normalize( path.join( __dirname, '..', '.temp' ) );
  target = path.join( targetRoot, filename.replace('.wav', '.mp3') );
  cacheHash = path.join( targetRoot, filename.replace('.wav', '.wav.hash') );

  beforeEach( () => {
    rimraf.sync(targetRoot);
    mkdirp.sync(targetRoot);
  });

  after( () => {
    rimraf.sync(targetRoot);
  });

  it( 'creates an MP3 without caching', async () => {
    await processFile(
      {
        assetName: path.parse(source).base,
        source: source,
        destination: target,
        targetsRoot: targetRoot,
        nocache: true,
        logger: nullLogger
      }
    );

    expect( fs.existsSync(target) ).to.be.true;
    expect( fs.existsSync(cacheHash) ).to.be.false;
  });


  // It looks like successive wav conversions will fail for now because the lame
  // library is throwing this error on node v14: https://github.com/nodejs/node/issues/32463
  let majorNodeVersion = parseInt( (/(\d+)/).exec(process.version)[0] );
  if ( majorNodeVersion >= 14 ) {
    return;
  }


  it( 'creates an MP3 with caching', async () => {
    await processFile(
      {
        assetName: path.parse(source).base,
        source: source,
        destination: target,
        targetsRoot: targetRoot,
        nocache: false,
        logger: nullLogger
      }
    );

    expect( fs.existsSync(target) ).to.be.true;
    expect( fs.existsSync(cacheHash) ).to.be.true;
  });

  it( 'avoids duplicate conversion with caching', async () => {
    await processFile(
      {
        assetName: path.parse(source).base,
        source: source,
        destination: target,
        targetsRoot: targetRoot,
        nocache: false,
        logger: nullLogger
      }
    );

    expect( fs.existsSync(target) ).to.be.true;
    expect( fs.existsSync(cacheHash) ).to.be.true;

    // note: previously this test used fs.statSync and mtime to determine
    // whether the file had been overwritten again. On Windows machines
    // this turned out to fail intermittently, possibly because the OS
    // touched the file for some reason.

    fs.unlinkSync(target);
    expect( fs.existsSync(target) ).to.be.false;

    await processFile(
      {
        assetName: path.parse(source).base,
        source: source,
        destination: target,
        targetsRoot: targetRoot,
        nocache: false,
        logger: nullLogger
      }
    );

    // the cache process should only have checked the MD5 of the source
    // and the hash in the cache file, so it should not have written the
    // destination
    expect( fs.existsSync(target) ).to.be.false;

    // now check to see that disabling the cache ignores the cache file
    await processFile(
      {
        assetName: path.parse(source).base,
        source: source,
        destination: target,
        targetsRoot: targetRoot,
        nocache: true,
        logger: nullLogger
      }
    );

    expect( fs.existsSync(target) ).to.be.true;

  });

});