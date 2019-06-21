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
const { match, stub } = require('sinon');

const commandHandler = require('../lib/aplCommandHandler');

const logger = console;

commandHandler.init({
  prefix: 'litexa'
});

describe('aplCommandHandler', function() {
  let errorStub = undefined;
  const errorPrefix = "This expected error wasn't logged: ";

  const cmds = [
    {
      type: 'SetPage',
      value: 1
    },
    {
      type: 'SpeakItem',
      componentId: 'myComponent'
    }
  ];

  beforeEach(function() {
    errorStub = stub(logger, 'error');
    commandHandler.commands = [];
  });

  afterEach(function() {
    errorStub.restore();
  });

  it('adds a single command', function() {
    const cmd = {
      type: 'Idle',
      delay: 3000
    };
    commandHandler.addCommands(cmd);
    expect(commandHandler.commands.length).to.equal(1);
    expect(commandHandler.commands[0]).to.deep.equal(cmd);
  });

  it('adds an array of commands', function() {
    commandHandler.addCommands(cmds);
    expect(commandHandler.commands.length).to.equal(2);
    expect(commandHandler.commands).to.deep.equal(cmds);
  });

  it('adds a speech command', function() {
    const suffix = '2';
    commandHandler.addSpeechCommand(suffix);
    const expectedCommands = [
      {
        type: 'SpeakItem',
        componentId: `${commandHandler.prefix}ID${suffix}`
      }
    ];
    expect(commandHandler.commands).to.deep.equal(expectedCommands);
  });

  it('ignores empty commands', function() {
    commandHandler.addCommands(void 0);
    expect(commandHandler.commands).to.be.empty;
    commandHandler.addCommands([]);
    expect(commandHandler.commands).to.be.empty;
  });

  it('rejects a non-object/array command', function() {
    commandHandler.addCommands('string');
    const expectedError = "Received non-array and non-object command of type 'string'";
    assert(errorStub.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
  });

  it('validates good commands', function() {
    commandHandler.addCommands(cmds);
    expect(commandHandler.areValidCommands()).to.be.true;
  });

  it('invalidates missing command type', function() {
    const cmd = {
      delay: 2000
    };
    commandHandler.addCommands(cmd);
    commandHandler.areValidCommands();
    const expectedError = "Found command with undefined 'type'";
    assert(errorStub.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
  });

  it('invalidates incorrect command parameter', function() {
    const cmd = {
      type: 'bogusType'
    };
    commandHandler.addCommands(cmd);
    commandHandler.areValidCommands();
    const expectedError = `Found invalid command type '${cmd.type}'`;
    assert(errorStub.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
  });

  it('invalidates incorrect command parameter', function() {
    const cmd = {
      type: 'SetPage',
      bogusParam: 2000
    };
    commandHandler.addCommands(cmd);
    commandHandler.areValidCommands();
    const expectedError = `Found invalid command parameter 'bogusParam' in '${cmd.type}'`;
    assert(errorStub.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
  });
});
