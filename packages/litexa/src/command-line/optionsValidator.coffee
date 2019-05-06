
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


###
# options is the object containing the options
# toValidate is a lift of objects with the option name to validate and a collection of valid examples
#
# e.g.
# toValidate = [{
#   name: 'myOptions'
#   valid: ['yes', 'no']
#   message: 'my Options has to be "yes" or "no"'
# }]
#
# and returns a list of error objects with option name and error message
# e.g.
#
# errors = [{
#   name: 'myOptions'
#   message : 'my Options has to be "yes" or "no"'
# }]
###

module.exports = (options, toValidate = [], removeInvalid = false) ->
  errors = []
  toValidate.forEach (validate) ->
    option = options[validate.name]
    return unless option?
    unless validate.valid.includes(option)
      delete options[validate.name] if removeInvalid
      errors.push({
        name: validate.name
        message: validate.message
      })
  errors
