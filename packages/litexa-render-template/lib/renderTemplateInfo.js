/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const TEMPLATE_INFO = {
  BodyTemplate1: {
    keys: ['background', 'title', 'primaryText', 'secondaryText', 'tertiaryText', 'displaySpeechAs']
  },
  BodyTemplate2: {
    keys: ['background', 'title', 'primaryText', 'secondaryText', 'tertiaryText', 'displaySpeechAs', 'image', 'hint']
  },
  BodyTemplate3: {
    keys: ['background', 'title', 'primaryText', 'secondaryText', 'tertiaryText', 'displaySpeechAs', 'image']
  },
  BodyTemplate6: {
    keys: ['background',          'primaryText', 'secondaryText', 'tertiaryText', 'displaySpeechAs',          'hint']
  },
  BodyTemplate7: {
    keys: ['background', 'title',                                                 'displaySpeechAs', 'image']
  },
  ListTemplate1: { // 'list' supports items with subset of ['token', 'primaryText', 'secondaryText', 'tertiaryText', 'image'] (checked at runtime)
    keys: ['background', 'title', 'list']
  },
  ListTemplate2: { // 'list' supports items with subset of ['token', 'primaryText', 'secondaryText',                 'image'] (checked at runtime)
    keys: ['background', 'title', 'list',                                                                     'hint']
  }
};

const VALID_TEMPLATE_TYPES = Object.keys(TEMPLATE_INFO);
const VALID_DISPLAY_SPEECH_AS_TYPES = ['primaryText', 'secondaryText', 'tertiaryText', 'title'];

module.exports = {
  TEMPLATE_INFO,
  VALID_TEMPLATE_TYPES,
  VALID_DISPLAY_SPEECH_AS_TYPES
}
