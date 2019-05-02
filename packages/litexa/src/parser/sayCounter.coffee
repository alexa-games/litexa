# keeps a total counter while expressing randomized
# statements to give each a unique ID

counter = 1

exports.reset = -> counter = 1

exports.get = ->
  val = counter
  counter += 1
  return val
