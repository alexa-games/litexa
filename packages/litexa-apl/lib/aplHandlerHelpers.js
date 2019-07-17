/*
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved.
 * These materials are licensed as "Restricted Program Materials" under the Program Materials
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service.
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html.
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized
 * terms not defined in this file have the meanings given to them in the Agreement.
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const {isEmpty} = require('./aplUtils');

const commandHandler = require('./aplCommandHandler');
const dataHandler = require('./aplDataHandler');
const documentHandler = require('./aplDocumentHandler');

const CUSTOM_PREFIX = 'litexa'; // this is a prefix used for insertions of any custom document component IDs, or data variables
const CHAR_CODE_OF_A = 97;      // used for unique a/b/c ID suffix generation

module.exports = {
  init: function(args = {}) {
    this.myData = args.myData || {};
    this.token = 'DEFAULT_TOKEN';
    this.language = this.myData.language || 'default';

    commandHandler.init({prefix: CUSTOM_PREFIX});
    dataHandler.init({prefix: CUSTOM_PREFIX});
    documentHandler.init({prefix: CUSTOM_PREFIX});
  },

  addToken: function(token) {
    if (isEmpty(token)) {
      return;
    }
    this.token = token;
  },

  addDocument: function(obj) {
    obj = this.sanitizeAssetReferences(obj);
    documentHandler.addDocument(obj);
  },

  addData: function(obj) {
    obj = this.sanitizeAssetReferences(obj);
    dataHandler.addData(obj);
  },

  addCommands: function(cmd) {
    commandHandler.addCommands(cmd);
  },

  // sanitization = clean up local file references + add unique suffixes to URLs
  sanitizeAssetReferences: function(obj) {
    if (!isEmpty(obj)) {
      let str = JSON.stringify(obj);
      str = this.replaceLocalAssetReferences(str);
      str = this.uniquifyAssetUrls(str);

      return(JSON.parse(str));
    } else {
      return obj;
    }
  },

  // This function does a quick and dirty replacement of any "assets://file_name" with the S3 URL
  // of that file_name.
  replaceLocalAssetReferences: function(str) {
    const regex = /assets:\/\/([^"]*)/g;
    const path = `${litexa.assetsRoot}${this.language}/`;

    return str.replace(regex, `${path}$1`);
  },

  // This function adds a unique suffix to all all asset URLs, if shouldUniqueURLs is set (during
  // development). This is done because Alexa otherwise skips re-downloading a file if the same
  // file name is found in cache (there's no checksum comparison).
  uniquifyAssetUrls: function(str) {
    if (this.myData.shouldUniqueURLs === 'true') {
      // @TODO: Might need to refine this regex to only check supported asset file extensions.
      const regex = /(\"source\"\:\"[^"]*)/g;
      const suffix = `#${new Date().getTime()}`;

      str = str.replace(regex, `$1${suffix}`)
    }
    return str;
  },

  addSpeech: function(speech) {
    if (isEmpty(speech)) {
      return;
    }

    if (typeof(speech) !== 'string') {
      console.error(`aplHandlerHelpers|addSpeakItem: Received non-string speech of type '${typeof(speech)}' > ignoring.`)
      return;
    }

    // Let's give each speech component a unique ID with:
    let suffix = (this.myData.curSpeechIndex).toString();

    let splitSpeech = this.splitSpeechByAudio(speech);

    if (splitSpeech.length > 1) {
      // We found at least one audio tag in our speech, which needs to be in its own SpeakItem.
      for (let i = 0; i < splitSpeech.length; ++i) {
        // Update the ID to stay unique for every child segment of this speech:
        let subSuffix = `${suffix}${String.fromCharCode(CHAR_CODE_OF_A + i)}`;
        this.checkAudioAndAddSpeakItem(splitSpeech[i], subSuffix);
      }
    } else {
      // Speech wasn't split up > add it as a whole.
      this.checkAudioAndAddSpeakItem(speech, suffix);
    }
  },

  splitSpeechByAudio: function(speech) {
    // If our speech has any audio tags, this returns an array of non-audio and audio speech segments.
    // Otherwise, it returns an array with the untouched speech as a single element.
    let results = speech.split(/(<audio src='[^']*'\/>)/).filter((s) => {return s.length !== 0});
    results = results.map(s => s.trim());
    return results;
  },

  checkAudioAndAddSpeakItem: function(speech, suffix) {
    const url = this.extractAudioURLIfFound(speech);
    const isURL = !isEmpty(url);

    if (isURL) {
      this.addSpeakItem({speech: url, suffix, isURL});
    } else {
      this.addSpeakItem({speech, suffix, isURL});
    }
  },

  extractAudioURLIfFound: function(speech) {
    const audioRegex = /<audio src='.*'\/>/;
    let url = '';
    if (speech.match(audioRegex)) {
      url = speech.replace(/<audio src='(.*)'\/>/, '$1');
    }
    return url;
  },

  addSpeakItem: function({speech, suffix, isURL = false}) {
    // Add a layout component with an ID, so we can reference it in our command/data.
    documentHandler.addSpeechContainer({speech, suffix, isURL});

    // Add a data object with the necessary SSML > speech transformer (in case this isn't a URL).
    dataHandler.addSpeechData({speech, suffix, isURL});

    // Add a 'SpeakItem' to the queue.
    commandHandler.addSpeechCommand(suffix);
  },

  createRenderDocumentDirective: function() {
    if (!documentHandler.isValidDocument()) {
      return;
    }

    let directive = {
      type: 'Alexa.Presentation.APL.RenderDocument',
      token: this.token,
      document: documentHandler.document,
      datasources: dataHandler.data
    }
    return directive;
  },

  createExecuteCommandsDirective: function() {
    if (!commandHandler.areValidCommands()) {
      return;
    }

    let directive = {
      type: 'Alexa.Presentation.APL.ExecuteCommands',
      token: this.token,
      commands: commandHandler.commands
    }
    return directive;
  }
}
