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

    const info = fs.statSync(target);

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

    const info2 = fs.statSync(target);
    expect( info.mtimeMs ).to.equal( info2.mtimeMs );
  });

});