module.exports = function (context) {

  console.log("Runtime require was constructed");

  let myData = {
    greeting: "Hello world. love, runtime require"
  };

  return {

    userFacing: {
      secret: 7,
      hello: function () {
        return `runtime says, ${myData.greeting}.`;
      }
    },

    events: {
      afterStateMachine: function () {
        context.say.push("Runtime require here, after state machine.");
        console.log("Runtime require peeping after state machine")
      },

      beforeFinalResponse: async (response) => {
        await new Promise((resolve, reject) => {
          let done = () => {
            if (!response.flags) {
              response.flags = {};
            }
            response.flags.runtimeRequireApproved = true;
            console.log("Runtime require checked final response");
            resolve();
          };
          setTimeout(done, 100);
        });
      }
    }

  };
}
