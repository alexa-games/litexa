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
