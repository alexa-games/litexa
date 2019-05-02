fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
crypto = require 'crypto'
rimraf = require 'rimraf'
ProjectConfig = require './project-config'

module.exports.run = (options) ->
  logger = options.logger ? console

  # nuke these directories if litexa config has changed
  locationsToWipe = ['.deploy', '.test']
  currentHash = ""
  storedHash = ""
  litexaProjectRoot = options.root
  try
    litexaConfigPath = await ProjectConfig.identifyConfigFileFromPath(options.root)
    currentHash = await createLitexaConfigSHA256(litexaConfigPath)
    litexaProjectRoot = path.parse(litexaConfigPath).dir
    for location, index in locationsToWipe
      locationsToWipe[index] = path.join litexaProjectRoot, location
  catch err
    return # do nothing if we don't have a litexa config

  litexaConfigHash = path.join litexaProjectRoot, '.deploy', 'litexaConfig.hash'
  try
    storedHash = fs.readFileSync litexaConfigHash, 'utf8'
  catch err
    # never mind
  if currentHash != storedHash
    for location in locationsToWipe
      rimraf.sync location
  mkdirp.sync path.join litexaProjectRoot, '.deploy'
  fs.writeFileSync litexaConfigHash, currentHash, 'utf8'


createLitexaConfigSHA256 = (configFile) ->
  new Promise (resolve, reject) ->
    shasum = crypto.createHash('sha256')
    fs.createReadStream configFile
    .on "data", (chunk) ->
      shasum.update chunk
    .on "end", ->
      resolve(shasum.digest('base64'))
    .on "error", (err) ->
      reject err
