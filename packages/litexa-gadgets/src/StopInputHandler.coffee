
###

 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved.
 * These materials are licensed as "Restricted Program Materials" under the Program Materials
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service.
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html.
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized
 * terms not defined in this file have the meanings given to them in the Agreement.
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 
###


class StopInputHandler
  constructor: () ->

  collectRequiredAPIs: (apis) -> apis["GAME_ENGINE"] = true

  toLambda: (output, indent, options) ->
    # stopInputHandler takes no arguments, but adds in
    # the last requestId as set back during startInputHandler
    # automatically, and then forgets that as a valid id.
    # It also guards that only one startInputHandler will
    # be added per response.
    # If there is no originatingRequestId (a startInputHandler
    # directive has not been sent), it will warn and not
    # send the directive.

    code = """
      var __directive = context.directives.find((a) => {
        a.type === 'GameEngine.StopInputHandler'
      });
      if (!__directive) { 
        var oldId = context.db.read("__lastInputHandler");
        if (oldId && oldId != 'cleared') {
          context.directives.push({ type:'GameEngine.StopInputHandler', originatingRequestId: oldId });
          context.db.write("__lastInputHandler", 'cleared');
        } else {
          console.log("WARNING: Did not send GameEngine.StopInputHandler because no current originatingRequestId was found in the database.");
        }
      }
    """

    for l in code.split '\n'
      output.push indent + l 

module.exports = StopInputHandler
