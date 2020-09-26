const childProcess = require("child_process");
const path = require("path");
const {expect} = require('chai');
require('coffeescript').register();
require('../../litexa/aliasing');
const builder = require('@src/command-line/skill-builder.coffee');

describe('integration test', () => {
  let root = path.join(__dirname,'skill');
  let skill = null;
  
  let runTest = async (options) => {
    if (!skill) {
      // ensure the dependency is installed
      childProcess.execSync('npm install', {cwd:path.join(__dirname,'skill','litexa')});
      skill = await builder.build(root);
    }

    return new Promise( (resolve, reject) => {
      skill.runTests(options, (err, result) => {
        if ( err ) {
          reject(err);
          return;
        }
        if ( !result.success ) {
          console.log(result);
        }
        resolve( result );
      });
    });
  };

  it('HTML statements produce the expected directives', async () => {
    let result = await runTest({ testDevice: 'show', logRawData: true });
    expect(result.success, "skill did not execute successfully").to.be.true;
    expect(result.directives.length, "only 1 directive").to.equal(1);

    let directive = result.directives[0];
    expect(directive.type).to.equal('Alexa.Presentation.HTML.Start');
    expect(directive.request).to.deep.equal({uri:'test://default/index.html'});
    expect(directive.data).to.deep.equal({greeting: 'Hello, player.'});
    expect(directive.transformers).to.deep.equal([{transformer: 'textToSpeech', inputPath: 'greeting'}]);
  }).timeout(10000);

  it('HTML statements do not produce directives when there is no interface', async () => {
    let result = await runTest({ testDevice: 'dot', logRawData: true });
    expect(result.success, "skill did not execute successfully").to.be.true;
    expect(result.directives.length, "no directives directive").to.equal(0);
  }).timeout(10000);

});