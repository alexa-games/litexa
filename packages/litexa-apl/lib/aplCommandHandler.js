const {isEmpty} = require('./aplUtils');
const {isValidCmdType, isValidCmdParam} = require('./aplCommandInfo');

module.exports = {
  init: function(args = {}) {
    this.prefix = args.prefix || '';
    this.commands = [];
  },

  addSpeechCommand: function(suffix) {
    let cmd = {
      type: 'SpeakItem',
      componentId: `${this.prefix}ID${suffix}`
    }
    this.addCommands(cmd);
  },

  addCommands: function(commands) {
    if (isEmpty(commands)) {
      // Nothing to add.
      return;
    }

    if (Array.isArray(commands)) {
      // Note: Don't concat, as that breaks the reference to the original array.
      this.commands.push(...commands);
    } else if (typeof(commands) === 'object') {
      this.commands.push(commands);
    } else {
      console.error(`aplCommandHandler|addCommands(): Received non-array and non-object command of type '${typeof(commands)}' > ignoring.`);
    }
  },

  areValidCommands: function(commands = this.commands) {
    for (let cmd of commands) {
      let type = cmd.type;
      if (isEmpty(type)) {
        console.error(`aplCommandHandler|areValidCommands(): Found command with undefined 'type' > rejecting commands.`);
        return false;
      }

      if (!isValidCmdType(type)) {
        console.error(`aplCommandHandler|areValidCommands(): Found invalid command type '${type}' > rejecting commands.`);
        return false;
      }

      for (let param of Object.keys(cmd)) {
        if (!isValidCmdParam(type, param)) {
          console.error(`aplCommandHandler|areValidCommands(): Found invalid command parameter '${param}' in '${type}' > rejecting commands.`);
          return false;
        }
      }
      return true;
    }
  }
}
