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

const { assert, expect } = require('chai');
const {match, stub} = require('sinon');

const dataHandler = require('../lib/aplDataHandler');

const logger = console;
const custPrefix = 'litexa';
const custSuffix = 'suffix';

dataHandler.init({
  prefix: custPrefix
});

describe('aplDataHandler', function() {
  let errorStub = undefined;
  const errorPrefix = "This expected error wasn't logged: ";

  beforeEach(function() {
    errorStub = stub(logger, 'error');
    dataHandler.data = {};
  });

  afterEach(function() {
    errorStub.restore();
  });

  it('rejects non-object and empty data', function() {
    let data = 'string';
    dataHandler.addData(data);
    const expectedError = `Tried adding a non-object or an array of type '${typeof data}'`;
    assert(errorStub.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);

    data = {};
    dataHandler.addData(data);
    expect(dataHandler.data).to.be.empty;
  });

  it('adds object data', function() {
    const data = {
      myData: {
        type: 'object',
        properties: {}
      }
    };
    dataHandler.addData(data);
    expect(dataHandler.data).to.deep.equal(data);
  });

  it('adds two different objects', function() {
    const firstData = {
      myData1: {
        type: 'object'
      }
    };
    const secondData = {
      myData2: {
        type: 'object'
      }
    };
    const expectedMergedData = {
      myData1: {
        type: 'object'
      },
      myData2: {
        type: 'object'
      }
    };
    dataHandler.addData(firstData);
    dataHandler.addData(secondData);
    expect(dataHandler.data).to.deep.equal(expectedMergedData);
  });

  it('partially merges two similar objects', function() {
    const firstData = {
      myData: {
        type: 'object',
        properties: {
          hintString: 'hint'
        }
      }
    };
    const secondData = {
      myData: {
        type: 'object',
        transformers: {
          inputPath: 'hintString',
          transformer: 'textToHint'
        }
      }
    };
    const expectedMergedData = {
      myData: {
        type: 'object',
        properties: {
          hintString: 'hint'
        },
        transformers: {
          inputPath: 'hintString',
          transformer: 'textToHint'
        }
      }
    };
    dataHandler.addData(firstData);
    dataHandler.addData(secondData);
    expect(dataHandler.data).to.deep.equal(expectedMergedData);
  });

  it('overwrites identical objects', function() {
    const firstData = {
      myData: {
        type: 'object'
      }
    };
    const secondData = {
      myData: {
        type: 'object'
      }
    };
    const expectedMergedData = {
      myData: {
        type: 'object'
      }
    };
    dataHandler.addData(firstData);
    dataHandler.addData(secondData);
    expect(dataHandler.data).to.deep.equal(expectedMergedData);
  });

  it('adds speech data for non-URL', function() {
    const testSpeech = 'This is test speech';
    dataHandler.addSpeechData({
      speech: testSpeech,
      suffix: 'suffix'
    });
    const expectedSpeechObject = {
      [`${custPrefix}SpeechObject${custSuffix}`]: {
        type: 'object',
        properties: {
          [`${custPrefix}SSML${custSuffix}`]: testSpeech
        },
        transformers: [
          {
            inputPath: `${custPrefix}SSML${custSuffix}`,
            outputName: `${custPrefix}Speech${custSuffix}`,
            transformer: 'ssmlToSpeech'
          }
        ]
      }
    };
    expect(dataHandler.data).to.deep.equal(expectedSpeechObject);
  });

  it('ignores speech URL', function() {
    const testSpeech = 'http://url';
    dataHandler.addSpeechData({
      speech: testSpeech,
      isURL: true
    });
    expect(dataHandler.data).to.be.empty;
  });
});
