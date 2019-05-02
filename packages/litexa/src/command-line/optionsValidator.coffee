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
