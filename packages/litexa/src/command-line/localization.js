const chalk = require('chalk');
const fs = require('fs');
const path = require('path');
const { promisify } = require('util');

const LoggingChannel = require('./loggingChannel');
const projectConfig = require('./project-config');
const { Skill } = require('@litexa/core/src/parser/skill');

/* The skill localization object has the following contents:
  {
    intents: {       // map of all skill intents, and model-ready utterances
      "SomeIntentName": {
        "default": [ // utterances parsed from the default Litexa files
          "default utterance {slot_name}",
          "default utterance {slot_name}"
        ],
        "fr-FR": [   // translated utterances added to the localization.json by a translator
          "french utterance {slot_name}",
          "french utterance {slot_name}"
        ]
      }
    },
    speech: { // map of all in-skill speech/reprompts, with any available translations
      "default speech string": { // say/reprompt string found in default Litexa files
        "fr-FR": "override string for FR"
      },
      "alternate one|alternate two|alternate three": { // say/reprompt 'or' alternates are delineated by | characters
        "fr-FR": "french alternate one|french alternate two"
      }
    }
  }
*/

// Utility function that will crawl Litexa code, to retrieve all intents/utterances and say/reprompts.
async function localizeSkill(options) {
  options.logger = options.logger || new LoggingChannel({
    logPrefix: 'localization',
    logStream: options.logStream || console,
    verbose: options.verbose || false
  });

  // Green log stream for any new content.
  options.logger.green = function (line) {
    options.logger.write({
      line,
      format: chalk.green
    });
  };

  // Red log stream for any orphaned content.
  options.logger.red = function (line) {
    options.logger.write({
      line,
      format: chalk.red
    });
  };

  try {
    const skill = await buildSkill(options);
    options.logger.log('parsing default skill intents, utterances, and output speech ...')

    const prevLocalization = { ...skill.projectInfo.localization };
    const curLocalization = skill.toLocalization();

    // Merge previous localization into the existing localization:
    // 1) Log any newly added intents, utterances, and speech lines in green, prefixed with '+'.
    // 2) Log any orphaned (no longer in skill) utterances and speech lines in red, prefixed with '-'.
    // Persist orphaned content in localization.json unless otherwise specified by --remove flags.
    mergePreviousLocalization(options, prevLocalization, curLocalization);
    const outputPath = path.join(skill.projectInfo.root, 'localization.json');
    const promisifiedFileWrite = promisify(fs.writeFile);
    await promisifiedFileWrite(outputPath, JSON.stringify(curLocalization, null, 2));
    options.logger.important(`localization summary saved to: ${outputPath}`);
  } catch (err) {
    options.logger.error(err);
    process.exit(1);
  }
}

async function buildSkill(options, variant = 'development') {
  const jsonConfig = await projectConfig.loadConfig(options.root);
  const projectInfo = new (require('./project-info'))({jsonConfig, variant, doNotParseExtensions: options.doNotParseExtensions});

  const skill = new Skill(projectInfo);
  skill.strictMode = true;

  for (const [language, languageInfo] of Object.entries(projectInfo.languages)) {
    const codeInfo = languageInfo.code;
    const files = codeInfo.files;
    for (const file of files) {
      const filename = path.join(codeInfo.root, file);
      const promisifiedFileRead = promisify(fs.readFile);
      const data = await promisifiedFileRead(filename, 'utf8');
      skill.setFile(file, language, data);
    }
  };

  return skill;
}

function mergePreviousLocalization(options, prevLocalization, curLocalization) {
  mergePreviousIntents(options, prevLocalization, curLocalization);
  mergePreviousUtterances(options, prevLocalization, curLocalization);
  mergePreviousSpeech(options, prevLocalization, curLocalization);
  // Perform any cloning steps after merging to not interleave cloning errors with merging process.
  // If CLI command specified from/to for cloning, copy everything to the target language.
  if (shouldPerformCloning(options)) {
    cloneUtterancesBetweenLocalizations(options, curLocalization);
    cloneSpeechBetweenLocalizations(options, curLocalization);
  }
}

function mergePreviousIntents(options, prevLocalization, curLocalization) {
  checkForNewIntents(options, prevLocalization, curLocalization);
  checkForOrphanedIntents(options, prevLocalization, curLocalization);
}

function mergePreviousUtterances(options, prevLocalization, curLocalization) {
  checkForNewUtterances(options, prevLocalization, curLocalization);
  checkForOrphanedUtterances(options, prevLocalization, curLocalization);
}

function mergePreviousSpeech(options, prevLocalization, curLocalization) {
  checkForNewSpeechLines(options, prevLocalization, curLocalization);
  checkForOrphanedSpeechLines(options, prevLocalization, curLocalization);
}

function shouldPerformCloning(options) {
  if (!options.cloneFrom && !options.cloneTo) {
    return false;
  }
  if (options.cloneTo === 'default') {
    throw new Error("Not allowed to clone localizations to `default` language.");
  }
  if (!options.cloneFrom) {
    throw new Error("Missing `cloneFrom` option. Please specify a Litexa language to clone from.");
  }
  if (!options.cloneTo) {
    throw new Error("Missing `cloneTo` option. Please specify a Litexa language to clone to.");
  }
  return true;
}

function checkForNewIntents(options, prevLocalization, curLocalization) {
  options.logger.verbose(`checking for new intents ...`);
  let numNewIntents = 0;
  let newIntentHeaderPrinted = false;

  for (const intent of Object.keys(curLocalization.intents)) {
    if (!prevLocalization.intents.hasOwnProperty(intent)) {
      if (!newIntentHeaderPrinted) {
        options.logger.warning(`the following intents are new since the last localization:`)
        newIntentHeaderPrinted = true;
      }
      options.logger.green(`+ ${intent}`);
      ++numNewIntents;
    }
  }

  options.logger.verbose(`number of new intents added since last localization: ${numNewIntents}`);
}

function checkForOrphanedIntents(options, prevLocalization, curLocalization) {
  options.logger.verbose(`checking for orphaned intents ...`)
  let numOrphanedIntents = 0;
  let orphanedIntentHeaderPrinted = false;

  for (const intent of Object.keys(prevLocalization.intents)) {
    if (!curLocalization.intents.hasOwnProperty(intent)) {
      // Logging orphaned intents in verbose output only, since Litexa automatically adds builtin intents to the skill
      // model depending on certain requirements.
      if (!orphanedIntentHeaderPrinted) {
        options.logger.verbose(`the following intents in localization.json are missing in skill:`)
        orphanedIntentHeaderPrinted = true;
      }
      options.logger.verbose(`- ${intent}`);
      ++numOrphanedIntents;
      // Persist the orphaned intent and all utterances within.
      curLocalization.intents[intent] = { ...prevLocalization.intents[intent] };
    }
  }

  options.logger.verbose(`number of localization intents that are missing in skill: ${numOrphanedIntents}`);
}

function checkForNewUtterances(options, prevLocalization, curLocalization) {
  options.logger.verbose(`checking for new utterances ...`)
  let numNewUtterances = 0;
  let newUtteranceHeaderPrinted = false;

  for (const intent of Object.keys(curLocalization.intents)) {
    const curUtterances = curLocalization.intents[intent]

    for (const utterance of Object.values(curUtterances.default)) {
      if (!prevLocalization.intents.hasOwnProperty(intent) || !prevLocalization.intents[intent].default.includes(utterance)) {
        if (!newUtteranceHeaderPrinted) {
          options.logger.warning(`the following utterances are new since the last localization:`)
          newUtteranceHeaderPrinted = true;
        }
        options.logger.green(`+ ${utterance}`);
        ++numNewUtterances;
      }
    }
  }
  options.logger.verbose(`number of new utterances added since last localization: ${numNewUtterances}`);
}

function checkForOrphanedUtterances(options, prevLocalization, curLocalization) {
  options.logger.verbose(`checking for orphaned utterances ...`)
  let numOrphanedUtterances = 0;
  let orphanedUtteranceHeaderPrinted = false;

  for (const intent of Object.keys(prevLocalization.intents)) {

    let intentObject = prevLocalization.intents[intent];

    for (const [language, utterances] of Object.entries(intentObject)) {
      if (language === 'default') {
        for (const utterance of utterances) {
          if (!curLocalization.intents[intent].default.includes(utterance)) {
            if (!orphanedUtteranceHeaderPrinted) {
              if (options.removeOrphanedUtterances) {
                options.logger.warning(`--remove-orphaned-utterances set -> going to remove the below utterances`);
              }
              options.logger.warning(`the following utterances in localization.json are missing in skill:`);
              orphanedUtteranceHeaderPrinted = true;
            }
            options.logger.red(`- ${utterance}`);
            ++numOrphanedUtterances;
            if (!options.removeOrphanedUtterances) {
              curLocalization.intents[intent].default.push(utterance);
            }
          }
        }
      } else {
        // For any non-default language, persist the existing translations.
        curLocalization.intents[intent][language] = [...utterances];
        if (!options.disableSortUtterances) {
          curLocalization.intents[intent][language] = localeSortArray(curLocalization.intents[intent][language]);
        }
      }
    }
    if (!options.disableSortLanguages) {
      curLocalization.intents[intent] = sortObjectByKeys(curLocalization.intents[intent]);
    }
  }

  if (options.removeOrphanedUtterances) {
    options.logger.verbose(`number of orphaned utterances removed from localization.json: ${numOrphanedUtterances}`);
  } else {
    options.logger.verbose(`number of localization.json utterances that are missing in skill: ${numOrphanedUtterances}`);
  }
}

function cloneUtterancesBetweenLocalizations(options, curLocalization) {
  let performedClone = false;
  for (const intent of Object.keys(curLocalization.intents)) {
    let intentObject = curLocalization.intents[intent];
    for (const language of Object.keys(intentObject)) {
      if (language === options.cloneFrom) {
        curLocalization.intents[intent][options.cloneTo] = curLocalization.intents[intent][options.cloneFrom];
        performedClone = true;
        break;
      }
    }
    if (!options.disableSortLanguages) {
      curLocalization.intents[intent] = sortObjectByKeys(curLocalization.intents[intent]);
    }
  }
  if (!performedClone) {
    options.logger.verbose(`No sample utterances were found for \`${options.cloneFrom}\`, so no utterances were cloned.`);
  }
}

function checkForNewSpeechLines(options, prevLocalization, curLocalization) {
  options.logger.verbose(`checking for new speech lines ...`)
  let numNewLines = 0;
  let newLinesHeaderPrinted = false;

  for (const line of Object.keys(curLocalization.speech)) {
    if (!prevLocalization.speech.hasOwnProperty(line)) {
      if (!newLinesHeaderPrinted) {
        options.logger.warning(`the following speech lines are new since the last localization:`)
        newLinesHeaderPrinted = true;
      }
      options.logger.green(`+ ${line}`);
      ++numNewLines;
    }
  }

  options.logger.verbose(`number of new speech lines added since last localization: ${numNewLines}`);
}

function checkForOrphanedSpeechLines(options, prevLocalization, curLocalization) {
  options.logger.verbose(`checking for orphaned speech lines ...`);
  let numOrphanedLines = 0;
  let orphanedHeaderPrinted = false;

  for (const [line, translations] of Object.entries(prevLocalization.speech)) {
    if (!curLocalization.speech.hasOwnProperty(line)) {
      if (!orphanedHeaderPrinted) {
        if (options.removeOrphanedSpeech) {
          options.logger.warning(`--remove-orphaned-speech set -> going to remove the below speech lines`);
        }
        options.logger.warning(`the following speech lines in localization.json are missing in skill:`);
        orphanedHeaderPrinted = true;
      }
      options.logger.red(`- ${line}`);
      ++numOrphanedLines;
    }
    if (curLocalization.speech.hasOwnProperty(line) || !options.removeOrphanedSpeech) {
      // Regardless of whether the speech line was orphaned, persist its translations in the output.
      curLocalization.speech[line] = options.disableSortLanguages ? { ...translations } : sortObjectByKeys({ ...translations });
    }
  }

  if (options.removeOrphanedSpeech) {
    options.logger.verbose(`number of orphaned speech lines removed from localization.json: ${numOrphanedLines}`);
  } else {
    options.logger.verbose(`number of localization.json speech lines that are missing in skill: ${numOrphanedLines}`);
  }
}

function cloneSpeechBetweenLocalizations(options, curLocalization) {
  let performedClone = false;
  for (const line of Object.keys(curLocalization.speech)) {
    if (curLocalization.speech[line].hasOwnProperty(options.cloneFrom)) {
      curLocalization.speech[line][options.cloneTo] = curLocalization.speech[line][options.cloneFrom];
      performedClone = true;
    } else if (options.cloneFrom === 'default') {
      curLocalization.speech[line][options.cloneTo] = line;
      performedClone = true;
    }
    if (!options.disableSortLanguages) {
      curLocalization.speech[line] = sortObjectByKeys(curLocalization.speech[line]);
    }
  }
  if (!performedClone) {
    options.logger.warning(`No speech was found for ${options.cloneFrom}, so no speech cloning occurred.`);
  }
}

function sortObjectByKeys(obj) {
  const sortedObj = {};
  Object.keys(obj).sort().forEach(function (key) {
    sortedObj[key] = obj[key];
  });

  return sortedObj;
}

function localeSortArray(arr) {
  const result = arr.sort(function (a, b) {
    // Custom sort for utterances that begin with a slot value "{slot} ..." to be higher in the list.
    if (a.startsWith('{') && !b.startsWith('{')) { return -1; }
    if (b.startsWith('{') && !a.startsWith('{')) { return 1; }

    return a.toLowerCase().localeCompare(b.toLowerCase());
  });

  return result;
}

module.exports = {
  localizeSkill
}
