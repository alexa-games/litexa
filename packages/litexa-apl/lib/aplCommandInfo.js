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

// These properties are supported by every one of the below commands.
const COMMON_COMMAND_PARAMS = [
  'type',          // required String; e.g. 'SpeakItem'
  'description',   // optional String; documentation
  'delay',         // optional Integer; delay in ms before command is executed
  'when'           // optional Boolean; conditional expression where if false, command is skipped
]

const COMMAND_INFO = {
  // animation commands
  AnimateItem: [
    'componentId', // required String; ID of the component to be animated
    'duration',    // required Integer; duration of the animation (in milliseconds)
    'value',       // required array of component transformations (opacity, translateX, translateY, rotate)
    'easing',      // optional String; transformation curve ['linear', 'ease-in', custom] (default: linear)
    'repeatCount', // optional Integer; number of times the animation will be repeated (default: 0)
    'repeatMode',  // optional String; how repeated animations will play; one of ['restart', 'reverse'] (default: restart)
  ],

  // Pager commands
  AutoPage: [
    'componentId', // required String; id of component to read
    'count',       // optional Integer; number of pages to show (default: all)
    'duration'     // optional Integer; number of ms to wait between pages (default: 0)
  ],
  SetPage: [
    'componentId', // required String; id of component to read
    'value',       // required integer; distance to move
    'position'     // one of [absolute|relative]; determines whether 'value' is absolute, or relative to current position
  ],               // Notes: no intermediate pages show

  // command bundlers
  Parallel: [
    'commands'     // required array of commands to execute in parallel (note, the parent 'delay' is added to every command's delay)
  ],
  Sequential: [
    'commands',    // required array of commands to execute in series
    'repeatCount'  // optional Integer; how often to repeat commands (default: 0)
  ],

  Idle: [],        // does nothing; can be combined with delay

  // ScrollView & Sequence commands
  Scroll: [
    'componentId', // required String id of the component to read
    'distance'     // number of pages to scroll (default: 1); can be negative
  ],               // Note: stops when one of: a) destination reached; b) end of content reached; c) touch event; d) voice prompt
  ScrollToIndex: [
    'align',       // optional first|last|center|visible (default: visible)
    'componentId', // required String id of component to read
    'index'        // required Integer; 0-based index of the child to read
  ],

  SendEvent: [     // Note: not supported by ExecuteCommand, and only supported with OnPress; needs to be packaged in TemplateRuntime.UserEvent
    'arguments',   // optional array of arguments (data to pass to Alexa)
    'components'   // optional array of Strings (components to extract value data from)
  ],

  SetState: [
    'componentId', // optional String; id of the component whose values should be set (if not set; component that issued the SetState is recipient)
    'state',       // required String; one of ['checked'|'disabled'|'focused']
    'value'        // required Boolean; value to set on the 'state'
  ],

  // speech commands
  SpeakItem: [
    'componentId',  // required String; id of component to read
    'align',        // optional one of [first|last|center|visible]; alignment of the item after scrolling (default: visible)
    'highlightMode' // optional one of [line|block]; how karaoke is applied (default: block); only applies to text components
  ],                // Note: karaoke state is auto-set to true during speech
  SpeakList: [
    'componentId',  // required String; id of the 'Sequence' or 'Container' to read
    'count',        // required Integer; number of children to read
    'start',        // required Integer; index of item to start with
    'align',        // optional one of [first|last|center|visible]; alignment of the item (default: visible)
    'minimumDwellTime' // optional Integer; minimum number of ms the item will be highlit (default: 0)
  ],

  // media commands
  PlayMedia: [
    'audioTrack',   // optional audio track to play on (default: foreground)
    'componentId',  // optional String; name of media playing component
    'source'        // required URL or source array of media to be played
  ],
  ControlMedia: [
    'command',      // required one of 'play'|'pause'|'next'|'previous'|'rewind'|'seek'|'setTrack'
    'componentId',  // source of media component (default: current component)
    'value'         // value to set for the command (used by 'seek' and 'setTrack')
  ]
}

const validCommandTypes = Object.keys(COMMAND_INFO);

const isValidCmdType = function(type) {
  return validCommandTypes.includes(type);
}

const getValidCmdTypes = function() {
  return validCommandTypes;
}

const isValidCmdParam = function(type, param) {
  return COMMON_COMMAND_PARAMS.includes(param) || COMMAND_INFO[type].includes(param);
}

const getValidCmdParams = function(type) {
  return COMMON_COMMAND_PARAMS.concat(COMMAND_INFO[type]);
}

module.exports = {
  isValidCmdType,
  isValidCmdParam,
  getValidCmdTypes,
  getValidCmdParams
}
