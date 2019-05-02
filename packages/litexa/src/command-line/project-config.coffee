###

  The project config file is a file at the root of a litexa project
  in the form litexa.[json/js/coffee] that when required
  specifies the litexa options for a project rooted in the
  same directory.

  loadConfig will load that config file, given a project path

  Note: the project name is assumed to be the same as the
  directory name, unless explicitly specified in the config file.

###

fs = require 'fs'
path = require 'path'
debug = require('debug')('litexa')
{ promisify } = require 'util'
CSON = require 'cson-parser'
extensions = require('./fileExtensions')
searchReplace = require('./generators/searchReplace')
projectNameValidate = require('./generators/validators/projectNameValidator')

pfs = {}
for f in ['stat', 'readdir']
  pfs[f] = promisify fs[f]

writeDefault = (location, language, name) ->
  debug "name is: #{name}"

  extension = extensions[language]
  filename = "litexa.#{extension}"

  writeFile = (file) ->
    source = path.join(__dirname, 'templates', 'common', language, file)

    data = fs.readFileSync(source, 'utf8')
    data = searchReplace(data, {name})

    file = path.join location, file
    fs.writeFileSync file, data, 'utf8'

  if language == 'typescript'
    language = "#{language}/config"
    writeFile('globals.d.ts')
    writeFile('tsconfig.json')
    writeFile('tslint.json')
    writeFile('package.json')

  writeFile(filename)
  return filename

identifyConfigFileFromPath = (location) ->
  # searches the given location and its ancestors for the first viable litexa config file
  debug "beginning search for a litexa config file at #{location}"

  isCorrectFilename = (fullpath) ->
    base = path.basename fullpath
    base.match /litexa\.(js|json|coffee|ts)/

  stat = await pfs.stat location
  if stat.isFile()
    unless isCorrectFilename location
      throw "The path #{location} is a file, but doesn't appear to point to a litexa config file."
    return location

  files = await pfs.readdir location
  for file in files
    continue unless isCorrectFilename file
    debug "found root: #{location}"

    return path.join location, file

  parent = path.normalize path.join location, '..'
  if parent != location
    return await identifyConfigFileFromPath parent

  throw "Failed to find a litexa config file (litexa.js/json/coffee) anywhere in #{location} or its
    ancestors."


loadConfig = (atPath, skillNameValidate = projectNameValidate) ->
  # Loads a project config file given a path, resolved by identifyConfigFileFromPath

  configLocation = await identifyConfigFileFromPath atPath
  projectRoot = path.dirname configLocation

  try
    tsCheck = /.*\.ts$/

    # Compile TypeScript
    if configLocation.match(tsCheck)
      ts = require('typescript')
      source = fs.readFileSync configLocation, 'utf8'
      compiledJS = ts.transpileModule(source, {
        compilerOptions: {
          target: ts.ScriptTarget.ES5,
          module: ts.ModuleKind.CommonJS
        }
      })
      configLocation = configLocation.replace(/\.ts/, '.js')
      fs.writeFileSync configLocation, compiledJS.outputText, 'utf8'

    config = require configLocation
    config.root = projectRoot
    throw "Couldn't parse the litexa config file at #{configLocation}: #{err}"

  unless config.name?
    config.name = path.basename config.root

  # Validate
  try
    skillNameValidate config.name
  catch err
    console.error "This project has an invalid name in its litexa config file. Please fix it and
      try again!"
    throw err

  # patch the deployment names into their objects for access later
  if config.deployments
    for name, deployment of config.deployments
      deployment.name = name

  return config


module.exports = {
  loadConfig: loadConfig
  writeDefault: writeDefault
  identifyConfigFileFromPath: identifyConfigFileFromPath
}
