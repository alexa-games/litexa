getNumbers = -> [3, 5, 8, 9]

getNames = ->
  driver: 'bob'
  artillery: 'tim'
  hacker: 'mary'

processJobAsync = (name) ->
  await new Promise (resolve, reject) ->
    setTimeout (-> resolve("the #{name}")), 50
