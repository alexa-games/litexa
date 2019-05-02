test = -> "test"
echo = (num, str, bool, obj, result) ->
  if num == 10 and str == 'test' and bool and obj.exists and result == 'test'
    return "success"
  return "nope"

class Thing
  constructor: ->
    @exists = true

  test: -> "thing test"

  echo: (num, str, bool, obj, result) ->
    if num == 10 and str == 'test' and bool and obj.exists and result == 'test'
      return "success"
    return "nope"
