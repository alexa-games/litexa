formatName = (name) ->
  path = require('path')
  nameFormatter = require('name-formatter')
  path.join 'something', nameFormatter.format name