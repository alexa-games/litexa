
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

  class InputHandlerEventIntent extends lib.EventIntent

    toLambda: (output, options) ->
      indent = "    "

      output.push "#{indent}if (context.db.read('__lastInputHandler') != context.request.originatingRequestId ) {"
      output.push "#{indent}  context.shouldDropSession = true;"
      output.push "#{indent}  return;"
      output.push "#{indent}}"

      super.toLambda output, options
