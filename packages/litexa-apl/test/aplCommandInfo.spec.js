const { expect } = require('chai');

const commandInfo = require('../lib/aplCommandInfo');

describe('aplCommandInfo', function() {
  it('checks validity of command type', function() {
    expect(commandInfo.isValidCmdType('Idle')).to.be.true;
    expect(commandInfo.isValidCmdType('Bogus')).to.be.false;
  });

  it('checks validity of command parameter', function() {
    expect(commandInfo.isValidCmdParam('Idle', 'when')).to.be.true;
    expect(commandInfo.isValidCmdParam('Idle', 'value')).to.be.false;
  });

  it('returns valid command types', function() {
    const commands = commandInfo.getValidCmdTypes();
    const expectedCommandTypes = [
      'AutoPage',
      'SetPage',
      'Parallel',
      'Sequential',
      'Idle',
      'Scroll',
      'ScrollToIndex',
      'SendEvent',
      'SetState',
      'SpeakItem',
      'SpeakList',
      'PlayMedia',
      'ControlMedia'
    ];
    expect(commands).to.deep.equal(expectedCommandTypes);
  });

  it('returns command parameters for a command type', function() {
    let validParams = commandInfo.getValidCmdParams('Idle');
    const expectedIdleParams = ['type', 'description', 'delay', 'when']; // 'Idle' only supports the common parameters
    expect(validParams).to.deep.equal(expectedIdleParams);

    validParams = commandInfo.getValidCmdParams('AutoPage');
    let autoPageParams = ['componentId', 'count', 'duration']; // 'AutoPage' supports these + common parameters
    autoPageParams = expectedIdleParams.concat(autoPageParams);
    expect(validParams).to.deep.equal(autoPageParams);
  });
});
