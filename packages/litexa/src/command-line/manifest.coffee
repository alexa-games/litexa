fs = require 'fs'
path = require 'path'
extensions = require('./fileExtensions')
searchReplace = require('./generators/searchReplace')

module.exports.create = (name, language) ->
  name = name.replace /[_\.\-]/gi, ' '
  name = name.replace /\s+/gi, ' '
  name = (name.split(' '))
  name = ( w[0].toUpperCase() + w[1...] for w in name )
  name = name.join ' '

  invocation = name.toLowerCase().replace /[^a-z0-9']/gi, ' '

  extension = extensions[language]

  if language == 'typescript'
    language = "#{language}/config"

  source = path.join(__dirname, 'templates', 'common', language, "skill.#{extension}")

  data = fs.readFileSync source, 'utf8'
  searchReplace(data, {name, invocation})
