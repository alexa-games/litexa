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