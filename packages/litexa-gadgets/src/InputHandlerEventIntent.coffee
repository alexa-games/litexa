
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


module.exports = (lib) ->
  class InputHandlerEventIntent extends lib.Intent
    constructor: (location, utterance) ->
      super location, utterance
      @startFunction = new lib.FunctionMap
      @haveNames = false

    setCurrentEventName: (name) ->
      @startFunction.setCurrentName name
      @haveNames = true unless name == '__'

    toLambda: (output, options) ->
      indent = "      "

      output.push "#{indent}if (context.db.read('__lastInputHandler') != context.request.originatingRequestId ) {"
      output.push "#{indent}  context.shouldDropSession = true;"
      output.push "#{indent}  return;"
      output.push "#{indent}}"

      options.scopeManager.pushScope @location, "inputHandlerEvent"
      output.push "{"
      if @startFunction?
        @startFunction.toLambda(output, indent, options, '__')
      output.push "}"
      options.scopeManager.popScope @location

      if @haveNames
        output.push "#{indent}for( var __eventIndex=0; __eventIndex<context.slots.request.events.length; ++__eventIndex) {"
        output.push "#{indent}var __event = context.slots.request.events[__eventIndex];"
        output.push "#{indent}context.slots.event = __event;"
        for eventName, func of @startFunction.functions
          continue if eventName == '__'
          options.scopeManager.pushScope @location, "inputHandlerEvent:#{eventName}"
          output.push "#{indent}  if(__event.name == '#{eventName}'){"
          @startFunction.toLambda(output, indent + '    ', options, eventName)
          output.push "#{indent}  }"
          options.scopeManager.popScope @location
        output.push "#{indent}};"


  return InputHandlerEventIntent
