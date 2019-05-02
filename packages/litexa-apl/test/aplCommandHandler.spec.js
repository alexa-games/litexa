const { assert, expect } = require('chai');
const { match, stub } = require('sinon');

const commandHandler = require('../lib/aplCommandHandler');

const logger = console;

commandHandler.init({
  prefix: 'litexa'
});

describe('aplCommandHandler', function() {
  let errorSpy = undefined;
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
    errorSpy = stub(logger, 'error');
    commandHandler.commands = [];
  });

  afterEach(function() {
    errorSpy.restore();
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
    assert(errorSpy.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
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
    assert(errorSpy.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
  });

  it('invalidates incorrect command parameter', function() {
    const cmd = {
      type: 'bogusType'
    };
    commandHandler.addCommands(cmd);
    commandHandler.areValidCommands();
    const expectedError = `Found invalid command type '${cmd.type}'`;
    assert(errorSpy.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
  });

  it('invalidates incorrect command parameter', function() {
    const cmd = {
      type: 'SetPage',
      bogusParam: 2000
    };
    commandHandler.addCommands(cmd);
    commandHandler.areValidCommands();
    const expectedError = `Found invalid command parameter 'bogusParam' in '${cmd.type}'`;
    assert(errorSpy.calledWith(match(expectedError)), `${errorPrefix}${expectedError}`);
  });
});
