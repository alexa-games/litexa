/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const helpers = require('./aplHandlerHelpers');
const {isEmpty} = require('./aplUtils');

module.exports = function(context) {
  const myData = {
    shouldUniqueURLs:
      isEmpty(process.env.shouldUniqueURLs) ? 'true' : process.env.shouldUniqueURLs,

    language:
      context.language || 'default',

    hasAPLSupport: function() {
      let {
        event: {
          context: {
            System: {
              device: {
                supportedInterfaces
              }
            }
          }
        }
      } = context;
      return supportedInterfaces.hasOwnProperty('Alexa.Presentation.APL');
    },

    curSpeechIndex: 0, // tracks which speech needs to be added next

    userEnabledCheck: null // custom function to disable APL callbacks
  }

  const checkForDocument = function() {
    for (let fragment of context.apl) {
      if (!isEmpty(fragment.document)) {
        return true;
      }
    }
    return false;
  }

  const parseDocumentStructure = function(document) {
    if (isEmpty(document)) {
      return;
    }

    // Check if this is an object wrapping document/datasources (as exported from APL Authoring Tool).
    if (document.hasOwnProperty('document')) {
      // If it is, just add the inner document.
      helpers.addDocument(document.document);
      // Let's also check for any variants of 'data' the user might have in here.
      if (document.hasOwnProperty('data')) {
        helpers.addData(document.data);
      }
      if (document.hasOwnProperty('datasources')) {
        helpers.addData(document.datasources);
      }
      if (document.hasOwnProperty('dataSources')) {
        helpers.addData(document.dataSources);
      }
    } else {
      // Otherwise, assume this is already the inner 'document'.
      helpers.addDocument(document);
    }
  }

  // Adds any speech that should be occurring before the next fragment.
  const addPreFragmentSpeech = function({
    index,
    aplIsSendingDocument = false,
    aplCommandsQueued = false
  }) {
    if (isEmpty(context.aplSpeechMarkers)) {
      // No speech marker for this fragment > do nothing.
      return;
    }

    const curMarker = context.aplSpeechMarkers[index];

    // Add speech up until this fragment's marker.
    while (myData.curSpeechIndex < curMarker) {
      if (aplIsSendingDocument) {
        helpers.addSpeech(context.say[myData.curSpeechIndex++]);
      } else if (aplCommandsQueued) {
        console.warn(`aplHandler|addPreFragmentSpeech: Sending say|soundEffects preceded by an APL command without an APL document. The say|soundEffects will play through outputSpeech BEFORE the APL command!`)
        break;
      }
    }
  }

  // Adds any remaining speech in the context.say queue, after processing all APL fragments.
  const addPostFragmentsSpeech = function({
    aplIsSendingDocument = false,
    aplCommandsQueued = false
  }) {
    const lastSpeechIndex = context.say.length - 1;

    while (myData.curSpeechIndex <= lastSpeechIndex) {
      if (aplIsSendingDocument) {
        helpers.addSpeech(context.say[myData.curSpeechIndex++]);
      } else if (aplCommandsQueued) {
        console.warn("aplHandler|addPostFragmentsSpeech: Sending say|soundEffects preceded by an APL command without an APL document. The say|soundEffects will play through outputSpeech BEFORE the APL command!")
        break;
      }
    }

    if (aplIsSendingDocument) {
      // Empty our context.say,since everything has been moved to APL.
      context.say = [];
    }
  }

  // checks to see if the user has disabled the APL callbacks
  const isUserDisabled = function() {
    if (typeof(myData.userEnabledCheck) == 'function') {
      if (!myData.userEnabledCheck(context)) {
        return true;
      }
    }
    return false;
  }

  return {
    userFacing: {
      // Allows users to check if APL is available.
      isEnabled: function() {
        return myData.hasAPLSupport() && !isUserDisabled();
      },

      setUserEnabledCheck: function(func) {
        myData.userEnabledCheck = func;
      }
    },

    events: {
      afterStateMachine: function() {
        if (isUserDisabled()) {
          return;
        }

        if (!isEmpty(context.apl) && myData.hasAPLSupport()) {

          // Let's first check for a document, to know whether we should interleave speech/sound:
          // If there's no document, we don't want to create one for our interleavable speech components
          // since doing so would override any potentially active document on the device, and would
          // thus break any standalone command directives.
          let aplIsSendingDocument = checkForDocument();
          // Keep track of queued commands, to know whether we should warn user of non-interleaved output.
          let aplCommandsQueued = false;

          helpers.init({myData});

          for (let i = 0; i < context.apl.length; ++i) {
            let fragment = context.apl[i];

            helpers.addToken(fragment.token);
            parseDocumentStructure(fragment.document);
            helpers.addData(fragment.data);

            addPreFragmentSpeech({
              index: i,
              aplIsSendingDocument,
              aplCommandsQueued
            });

            if (!isEmpty(fragment.commands)) {
              helpers.addCommands(fragment.commands);
              aplCommandsQueued = true;
            }

            if (i === context.apl.length - 1) {
              // This was the last APL fragment > convert all remaining speech.
              addPostFragmentsSpeech({
                aplIsSendingDocument,
                aplCommandsQueued
              });
            }
          }

          let renderDirective = helpers.createRenderDocumentDirective();
          if (!isEmpty(renderDirective)) {
            context.directives.push(renderDirective);
          }

          let commandsDirective = helpers.createExecuteCommandsDirective();
          if (!isEmpty(commandsDirective)) {
            context.directives.push(commandsDirective);
          }
        }
      },

      beforeFinalResponse: function(response) {
        if (isUserDisabled()) {
          return;
        }

        if (!isEmpty(response.directives)) {
          let aplFound = false;
          let renderTemplateIndex = -1;

          for (let i = 0; i < response.directives.length; ++i) {
            switch (response.directives[i].type) {
              case 'Alexa.Presentation.APL.RenderDocument':
              case 'Alexa.Presentation.APL.ExecuteCommands':
                aplFound = true;
                break;
              case 'Display.RenderTemplate':
                renderTemplateIndex = i;
                break;
            }
          }

          if (aplFound && renderTemplateIndex > -1) {
            console.warn(`aplHandler|beforeFinalResponse(): Found a Display.RenderTemplate directive alongside an APL directive! The two directives are incompatible - removing: ${JSON.stringify(response.directives[renderTemplateIndex])}`);
            response.directives.splice(renderTemplateIndex, 1);
          }
        }
      }
    }
  }
}
