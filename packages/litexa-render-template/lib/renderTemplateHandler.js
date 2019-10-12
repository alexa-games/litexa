/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const Helpers = require('./handlerHelpers')
const {isEmpty} = require('./renderTemplateUtils')

module.exports = function(context) {
  const myData = {
    shouldUniqueURLs:
      isEmpty(process.env.shouldUniqueURLs) ? 'true' : process.env.shouldUniqueURLs,

    language:
      context.language || '',

    hasDisplay: function() {
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
      return supportedInterfaces.hasOwnProperty('Display');
    }
  }

  return {
    userFacing: {
      // Allows users to check if RenderTemplate is available.
      isEnabled: function() {
        return myData.hasDisplay();
      }
    },
    events: {
      afterStateMachine: function() {
        if (context.screen && myData.hasDisplay()) {
          let screen = context.screen;

          let renderDirective = {
            type: "Display.RenderTemplate",
            template: {
              type: screen.template,
              backButton: "HIDDEN",
              title: screen.title || ''
            }
          }
          let template = renderDirective.template;

          Helpers.init({template, myData});
          Helpers.addImage(screen.background, 'backgroundImage');

          if (screen.list) {
            Helpers.addList(screen.list);
          } else {
            // If there's no list, check and add any BodyTemplate attributes.
            for (let type of ['primaryText', 'secondaryText', 'tertiaryText']) {
              Helpers.addText(screen[type], type);
            }
            Helpers.addImage(screen.image, 'image');
            Helpers.addDisplaySpeechAs(context.say, screen.displaySpeechAs);
          }

          context.directives.push(renderDirective);

          if (screen.hasOwnProperty('hint') && typeof(screen.hint) === 'string') {
            const hintDirective = {
              type: "Hint",
              hint: {
                type: "PlainText",
                text: screen.hint
              }
            }
            context.directives.push(hintDirective);
          }
        }
      }
    }
  };
}
