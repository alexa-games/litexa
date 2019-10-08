/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const {isEmpty} = require('./aplUtils');
const merge = require('./aplFragmentMerger');

module.exports = {
  init: function(args = {}) {
    this.prefix = args.prefix || '';
    this.data = {};
  },

  addSpeechData: function({
    speech = '',
    suffix,
    isURL = false
  }) {
    if (isURL) {
      // We don't need to add any speech transformers if this is a URL.
      return;
    }

    /*
      Adds an object, so we can transform our SSML to speech. An object supports the following attributes:
        'type',         // required; has to be 'object'
        'properties',
        'objectID',
        'description',
        'transformers'  // array of transformer objects of type ['ssmlToSpeech', 'ssmlToText', 'textToHint']
    */
    const speechObject = {
      [`${this.prefix}SpeechObject${suffix}`]: {
        type: 'object',
        properties: {
          [`${this.prefix}SSML${suffix}`]: `<speak>${speech}</speak>`
        },
        transformers: [
          {
            inputPath: `${this.prefix}SSML${suffix}`,
            outputName: `${this.prefix}Speech${suffix}`,
            transformer: 'ssmlToSpeech'
          }
          /* Leaving this commented for now, in case we opt to make the text transformer/output available, for convenience.
          {
            inputPath: `${this.prefix}SSML${suffix}`,
            outputName: `${this.prefix}Text${suffix}`,
            transformer: 'ssmlToText'
          }
          */
        ]
      }
    }
    this.addData(speechObject);
  },

  addData: function(obj) {
    if (isEmpty(obj)) {
      // Nothing to merge.
      return;
    }

    if (typeof(obj) !== 'object' || Array.isArray(obj)) {
      console.error(`aplDataHandler|addData(): Tried adding a non-object or an array of type '${typeof(obj)}' > ignoring.`)
      return;
    }

    this.data = merge(this.data, obj);
  }
}
