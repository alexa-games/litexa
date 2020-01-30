const { expect } = require('chai');
const assert = require('assert');
const sinon = require('sinon');
const rimraf = require('rimraf');
const fs = require('fs');
const path = require('path');

const localization = require('@src/command-line/localization');
const { Intent, FilteredIntent } = require('@src/parser/intent.coffee').lib

const testSkillDirectory = 'localization-test-skill';

class RecordingLogger {
  constructor() {
    this.errors = [];
    this.importantLogs = []
    this.logs = [];
    this.verboseLogs = [];
    this.warningLogs = [];
    this.writeLogs = [];
  }
  
  error(err) {
    this.errors.push(err.message);
  }

  important(line) {
    this.importantLogs.push(line);
  }

  log(line) {
    this.logs.push(line);
  }

  verbose(line) {
    this.verboseLogs.push(line);
  }

  warning(line) {
    this.warningLogs.push(line);
  }

  write({line}) {
    this.writeLogs.push(line);
  }
}

function createOptionsObject() {
  return {
    root: path.join(__dirname, testSkillDirectory),
    logger: new RecordingLogger(),
    doNotParseExtensions: true
  }
}

describe('localization command', async () => {
  let options = undefined;

  doMemoryCleanup = () => {
    Intent.unregisterUtterances();
    delete require.cache[path.join(options.root, 'localization.json')];
  }

  beforeEach(async () => {
    options = createOptionsObject();
    if (!fs.existsSync(path.join(options.root, 'litexa'))) {
      fs.mkdirSync(path.join(options.root, 'litexa'));
    }
  });

  afterEach(async () => {
    doMemoryCleanup();
    rimraf.sync(path.join(options.root, 'litexa'));
    rimraf.sync(path.join(options.root, 'localization.json'));
  });


  describe('localizing speech output', async () => {
    const litexaContent = [
      'launch',
      '  say "say line 1."',
      '  say "say line 2."',
      '  reprompt "reprompt line 1."',
      '  reprompt "reprompt line 2."',
      '',
      'stateA',
      '  say "say line 3."',
      '  reprompt "reprompt line 3."'
    ]

    beforeEach(async () => {
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), litexaContent.join('\n'));
      await localization.localizeSkill(options);
      doMemoryCleanup();
    });

    it('added a say line', async () => {
      const skillCode = [...litexaContent];
      skillCode.push('  say "say line 4."');
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), skillCode.join('\n'));
      options = createOptionsObject();
      await localization.localizeSkill(options);

      expect(options.logger.verboseLogs[9]).to.equal('number of new speech lines added since last localization: 1');
      expect('+ say line 4.').to.equal(options.logger.writeLogs[0]);
    });

    it('changed a say line, disabled removeOrphanedSpeech', async () => {
      const skillCode = [...litexaContent];
      skillCode[1] = '  say "modified say line 1."';
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), skillCode.join('\n'));
      options = createOptionsObject();

      await localization.localizeSkill(options);
      expect(options.logger.verboseLogs[9]).to.equal('number of new speech lines added since last localization: 1');
      expect(options.logger.verboseLogs[11]).to.equal('number of localization.json speech lines that are missing in skill: 1');
      expect('+ modified say line 1.').to.equal(options.logger.writeLogs[0]);
      expect('- say line 1.').to.equal(options.logger.writeLogs[1]);
    });

    it('changed a say line, enabled removeOrphanedSpeech', async () => {
      const skillCode = [...litexaContent];
      skillCode[1] = '  say "modified say line 1."';
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), skillCode.join('\n'));
      options = createOptionsObject();
      options.removeOrphanedSpeech = true

      await localization.localizeSkill(options);
      expect(options.logger.verboseLogs[9]).to.equal('number of new speech lines added since last localization: 1');
      expect(options.logger.verboseLogs[11]).to.equal('number of orphaned speech lines removed from localization.json: 1');
      expect('+ modified say line 1.').to.equal(options.logger.writeLogs[0]);
      expect('- say line 1.').to.equal(options.logger.writeLogs[1]);
    });

    it('deleted a say line, disabled removeOrphanedSpeech', async () => {
      const skillCode = [...litexaContent];
      skillCode.splice(2,1);
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), skillCode.join('\n'));
      options = createOptionsObject();

      await localization.localizeSkill(options);
      expect(options.logger.verboseLogs[9]).to.equal('number of new speech lines added since last localization: 0');
      expect(options.logger.verboseLogs[11]).to.equal('number of localization.json speech lines that are missing in skill: 1');
      expect('- say line 2.').to.equal(options.logger.writeLogs[0]);
    });

    it('deleted a say line, enabled removeOrphanedSpeech', async () => {
      const skillCode = [...litexaContent];
      skillCode.splice(3,1);
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), skillCode.join('\n'));
      options = createOptionsObject();
      options.removeOrphanedSpeech = true

      await localization.localizeSkill(options);
      expect(options.logger.verboseLogs[9]).to.equal('number of new speech lines added since last localization: 0');
      expect(options.logger.verboseLogs[11]).to.equal('number of orphaned speech lines removed from localization.json: 1');
      expect('- reprompt line 1.').to.equal(options.logger.writeLogs[0]);
    });
  });

  describe('localizing utterances', async () => {
    const litexaContent = [
      'launch',
      '  say "say line 1."',
      '  reprompt "reprompt line 1."',
      '  when "yes intent"',
      '    or "yes"',
      '    say "say yes intent."',
      '  when AMAZON.NoIntent',
      '    or "no intent"',
      '    or "no"',
      '    say "say no intent."',
    ]

    beforeEach(async () => {
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), litexaContent.join('\n'));
      await localization.localizeSkill(options);
      doMemoryCleanup();
    });

    it('added an utterance', async () => {
      const skillCode = [...litexaContent];
      skillCode.splice(4, 0, '    or "added yes utterance"');
      skillCode.splice(8, 0, '    or "added no utterance"');
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), skillCode.join('\n'));
      options = createOptionsObject();

      await localization.localizeSkill(options);
      expect(options.logger.verboseLogs[5]).to.equal('number of new utterances added since last localization: 2',);
      expect('+ added yes utterance').to.equal(options.logger.writeLogs[0]);
      expect('+ added no utterance').to.equal(options.logger.writeLogs[1]);
    });

    it('changed an utterance, disabled removeOrphanedUtterances', async () => {
      const skillCode = [...litexaContent];
      skillCode[4] = '    or "modified yes utterance"';
      skillCode[7] = '    or "modified no utterance"';
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), skillCode.join('\n'));
      options = createOptionsObject();

      await localization.localizeSkill(options);
      expect(options.logger.verboseLogs[5]).to.equal('number of new utterances added since last localization: 2');
      expect(options.logger.verboseLogs[7]).to.equal('number of localization.json utterances that are missing in skill: 2');
      expect('+ modified yes utterance').to.equal(options.logger.writeLogs[0]);
      expect('+ modified no utterance').to.equal(options.logger.writeLogs[1]);
      expect('- yes').to.equal(options.logger.writeLogs[2]);
      expect('- no intent').to.equal(options.logger.writeLogs[3]);
    });

    it('changed an utterance, enabled removeOrphanedUtterances', async () => {
      const skillCode = [...litexaContent];
      skillCode[4] = '    or "modified yes utterance"';
      skillCode[7] = '    or "modified no utterance"';
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), skillCode.join('\n'));
      options = createOptionsObject();
      options.removeOrphanedUtterances = true;

      await localization.localizeSkill(options);
      expect(options.logger.verboseLogs[5]).to.equal('number of new utterances added since last localization: 2');
      expect(options.logger.verboseLogs[7]).to.equal('number of orphaned utterances removed from localization.json: 2');
      expect('+ modified yes utterance').to.equal(options.logger.writeLogs[0]);
      expect('+ modified no utterance').to.equal(options.logger.writeLogs[1]);
      expect('- yes').to.equal(options.logger.writeLogs[2]);
      expect('- no intent').to.equal(options.logger.writeLogs[3]);
    });

    it('deleted an utterance, disabled removeOrphanedUtterances', async () => {
      const skillCode = [...litexaContent];
      skillCode.splice(4,1);
      skillCode.splice(6,1);
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), skillCode.join('\n'));
      options = createOptionsObject();

      await localization.localizeSkill(options);
      expect(options.logger.verboseLogs[5]).to.equal('number of new utterances added since last localization: 0');
      expect(options.logger.verboseLogs[7]).to.equal('number of localization.json utterances that are missing in skill: 2');
      expect('- yes').to.equal(options.logger.writeLogs[0]);
      expect('- no intent').to.equal(options.logger.writeLogs[1]);
    });
    it('deleted an utterance, enabled removeOrphanedUtterances', async () => {
      const skillCode = [...litexaContent];
      skillCode.splice(4,1);
      skillCode.splice(6,1);
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), skillCode.join('\n'));
      options = createOptionsObject();
      options.removeOrphanedUtterances = true;

      await localization.localizeSkill(options);
      expect(options.logger.verboseLogs[5]).to.equal('number of new utterances added since last localization: 0');
      expect(options.logger.verboseLogs[7]).to.equal('number of orphaned utterances removed from localization.json: 2');
      expect('- yes').to.equal(options.logger.writeLogs[0]);
      expect('- no intent').to.equal(options.logger.writeLogs[1]);
    });
  });

  describe('localizing intents', async () => {
    const litexaContent = [
      'launch',
      '  say "say line 1."',
      '  reprompt "reprompt line 1."',
      '  when "yes intent"',
      '    or "yes"',
      '    say "say yes intent."',
      '  when AMAZON.NoIntent',
      '    or "no intent"',
      '    or "no"',
      '    say "say no intent."',
    ]

    beforeEach(async () => {
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), litexaContent.join('\n'));
      await localization.localizeSkill(options);
      doMemoryCleanup();
    });

    it('added an intent', async () => {
      const skillCode = [...litexaContent];
      skillCode.push('  when AMAZON.HelpIntent');
      skillCode.push('  when "new intent"');
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), skillCode.join('\n'));
      options = createOptionsObject();
      await localization.localizeSkill(options);
      expect(options.logger.verboseLogs[1]).to.equal('number of new intents added since last localization: 2');
      expect(options.logger.verboseLogs[5]).to.equal('number of new utterances added since last localization: 1');
      expect('+ AMAZON.HelpIntent').to.equal(options.logger.writeLogs[0]);
      expect('+ NEW_INTENT').to.equal(options.logger.writeLogs[1]);
      expect('+ new intent').to.equal(options.logger.writeLogs[2]);
    });

    it('changed an intent', async () => {
      const skillCode = [...litexaContent];
      skillCode[3] = '  when "modified yes intent"';
      
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), skillCode.join('\n'));
      options = createOptionsObject();
      
      await localization.localizeSkill(options);
      expect(options.logger.verboseLogs[1]).to.equal('number of new intents added since last localization: 1');
      expect(options.logger.verboseLogs[3]).to.equal('the following intents in localization.json are missing in skill:');
      expect(options.logger.verboseLogs[4]).to.equal('- YES_INTENT');
      expect(options.logger.verboseLogs[7]).to.equal('number of new utterances added since last localization: 2');
      expect('+ MODIFIED_YES_INTENT').to.equal(options.logger.writeLogs[0]);
      expect('+ modified yes intent').to.equal(options.logger.writeLogs[1]);
      expect('+ yes').to.equal(options.logger.writeLogs[2]);
    });

    it('deleted an intent', async () => {
      const skillCode = [...litexaContent];
      skillCode.splice(6,3);
      
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), skillCode.join('\n'));
      options = createOptionsObject();
      
      await localization.localizeSkill(options);
      expect(options.logger.verboseLogs[1]).to.equal('number of new intents added since last localization: 0');
      expect(options.logger.verboseLogs[3]).to.equal('the following intents in localization.json are missing in skill:');
      expect(options.logger.verboseLogs[4]).to.equal('- AMAZON.NoIntent');
      expect(options.logger.verboseLogs[5]).to.equal('number of localization intents that are missing in skill: 1');
      expect(options.logger.verboseLogs[7]).to.equal('number of new utterances added since last localization: 0');
      expect(0).to.equal(options.logger.writeLogs.length);
    });
  });

  describe('cloning languages', async () => {
    const litexaContent = [
      'launch',
      '  say "say line 1."',
      '  reprompt "reprompt line 1."',
      '  when "yes intent"',
      '    or "yes"',
      '    say "say yes intent."',
      '  when AMAZON.NoIntent',
      '    or "no intent"',
      '    or "no"',
      '    say "say no intent."',
      '  when NumberIntent',
      '    or "number $number"',
      '    or "$number"',
      '    or "$number cats"',
      '    or "$number cat"',
      '    with $number = AMAZON.NUMBER',
      '    say "Got number intent with value $number."'
    ]
    before(async () => {
      sinon.stub(process, 'exit');
    })

    after(async () => {
      process.exit.restore();
    });

    beforeEach(async () => {
      fs.writeFileSync(path.join(options.root, 'litexa', 'main.litexa'), litexaContent.join('\n'));
      await localization.localizeSkill(options);
      doMemoryCleanup();
    });

    it('should clone a language and sort strings given valid parameters', async () => {
      options = createOptionsObject();
      options.cloneFrom = 'default';
      options.cloneTo = 'en-US';
      await localization.localizeSkill(options);
      doMemoryCleanup();

      options = createOptionsObject();
      options.cloneFrom = 'en-US';
      options.cloneTo = 'en';
      await localization.localizeSkill(options);

      const localizationJson = JSON.parse(fs.readFileSync(path.join(options.root, 'localization.json'), 'utf8'));

      const intents = Object.keys(localizationJson.intents);
      intents.forEach((intent) => {
        expect(Object.keys(localizationJson.intents[intent])).to.deep.equal(['default','en','en-US']);
        expect(localizationJson.intents[intent]['en-US']).to.deep.equal(localizationJson.intents[intent]['en']);
        // no test to compare to default because default does not get sorted
      });
      const sayStrings = Object.keys(localizationJson.speech);
      sayStrings.forEach((sayString) => {
        expect(Object.keys(localizationJson.speech[sayString])).to.deep.equal(['en','en-US']);
        expect(sayString).to.deep.equal(localizationJson.speech[sayString]['en']);
        expect(sayString).to.deep.equal(localizationJson.speech[sayString]['en-US']);
      });
    });

    it('should warn when there was nothing to clone', async () => {
      options = createOptionsObject();
      await localization.localizeSkill(options);
      const originalLocalizationJson = JSON.parse(fs.readFileSync(path.join(options.root, 'localization.json'), 'utf8'));
      doMemoryCleanup();

      options = createOptionsObject();
      options.cloneFrom = 'non-existent';
      options.cloneTo = 'en';
      await localization.localizeSkill(options);
      expect(options.logger.verboseLogs[12]).to.equal('No sample utterances were found for `non-existent`, so no utterances were cloned.');
      expect(options.logger.warningLogs[0]).to.equal('No speech was found for non-existent, so no speech cloning occurred.');
      const cloneResultLocalizationJson = JSON.parse(fs.readFileSync(path.join(options.root, 'localization.json'), 'utf8'));
      expect(originalLocalizationJson).to.deep.equal(cloneResultLocalizationJson);
    });

    it('should not clone a language if it is missing the source', async () => {
      options = createOptionsObject();
      options.cloneTo = 'en';
      await localization.localizeSkill(options);
      expect(options.logger.errors[0]).to.equal('Missing `cloneFrom` option. Please specify a Litexa language to clone from.');
      assert(process.exit.called);
      assert(process.exit.calledWith(1));
    });

    it('should not clone a language if it is missing the target', async () => {
      options = createOptionsObject();
      options.cloneFrom = 'en';
      await localization.localizeSkill(options);
      expect(options.logger.errors[0]).to.equal('Missing `cloneTo` option. Please specify a Litexa language to clone to.');
      assert(process.exit.called);
      assert(process.exit.calledWith(1));
    });

    it('should not allow "default" as a clone target', async () => {
      options = createOptionsObject();
      options.cloneFrom = 'en';
      options.cloneTo = 'default';
      await localization.localizeSkill(options);
      expect(options.logger.errors[0]).to.equal('Not allowed to clone localizations to `default` language.');
      assert(process.exit.called);
      assert(process.exit.calledWith(1));
    });
  });
});
