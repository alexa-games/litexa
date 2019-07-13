/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const audioCommand = {
  type: 'SpeakItem',
  componentId: 'audioItemId'
}

const interLeaveSpeechCommand = {
  type: 'SpeakItem',
  componentId: 'speechItemId'
}

const autoPageCommand = {
  type: 'AutoPage',
  componentId: 'pagerComponentId',
  duration: 5000
}

const turnPageCommands = [
  {
    type: 'Idle',
    delay: 2000
  },
  {
    type: 'SetPage',
    componentId: 'pagerComponentId',
    position: 'relative',
    value: 1
  }
]

function printRequestData(request) {
  console.log(`request was ${JSON.stringify(request)}`);
}
