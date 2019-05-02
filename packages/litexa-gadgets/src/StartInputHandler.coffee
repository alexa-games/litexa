class StartInputHandler
  constructor: (@expression) ->

  collectRequiredAPIs: (apis) -> apis["GAME_ENGINE"] = true

  toLambda: (output, indent, options) ->
    expression = @expression.toLambda(options)

    # startInputHandler ensures only one directive of
    # its kind is present, favoring the last submitted

    # it checks to see the directive is the right type

    # it records the current requestId, to be used later
    # as the originatingRequestId

    code = """
      context.directives = context.directives.filter( (a) => {
        var isStart = a.type === 'GameEngine.StartInputHandler';
        if (isStart) {
          console.error('encountered duplicate startInputHandler at line #{@location?.start?.line}. The previous one will be removed');
        }
        return !isStart;
      } );
      var __directive = #{expression};
      if (!__directive) {
        throw new Error('expression at line #{@location?.start?.line} did not return anything, it should return an object definition a single startInputHandler directive');
      }
      if (__directive.type !== 'GameEngine.StartInputHandler') {
        throw new Error('object returned at line #{@location?.start?.line} did not have the expected type GameEngine.StartInputHandler');
      }
      context.directives.push(__directive);
      context.db.write("__lastInputHandler", context.requestId);
    """

    for l in code.split '\n'
      output.push indent + l


module.exports = StartInputHandler
