module.exports = (stringTemplate, templateValues) ->
  data = stringTemplate
  for key, value of templateValues
    match = ///\{#{key}\}///g
    data = data.replace(match, value)

  data
