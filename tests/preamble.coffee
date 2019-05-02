mkdirp = require 'mkdirp'
path = require 'path'
fs = require 'fs'
rimraf = require 'rimraf'
{ spawnSync } = require 'child_process'

Skill = require('@litexa/core/src/parser/skill')
ProjectInfo = require('@litexa/core/src/command-line/project-info')

class exports.Logger
  constructor: (@name) ->
    @disableColor = true
    @path = path.join testRoot, @name + '.log'
    fs.writeFileSync @path, "", 'utf8'

  log: ->
    line = []
    for a in arguments
      line.push "" + a
    line += '\n'
    fs.appendFileSync @path, line, 'utf8'

  error: ->
    line = []
    for a in arguments
      line.push "" + a
    line += '\n'
    fs.appendFileSync @path, line, 'utf8'


exports.runSkill = (name) ->
  root = path.join __dirname, 'data', name

  cleanTempDirectories = ->
    new Promise (resolve, reject) ->
      rimraf.sync path.join root, '.test'
      rimraf.sync path.join root, '.deploy'
      rimraf.sync path.join root, '.logs'
      resolve()

  cleanNPM = ->
    new Promise (resolve, reject) ->
      rimraf.sync path.join root, 'node_modules'
      rimraf.sync path.join root, 'litexa', 'node_modules'
      try
        fs.unlinkSync path.join root, 'package-lock.json'
      resolve()

  installNPM = ->
    await cleanNPM()
    await new Promise (resolve, reject) ->
      installAt = (loc) ->
        if fs.existsSync path.join loc, 'package.json'
          try
            fs.unlinkSync path.join root, 'package-lock.json'
          spawnSync 'npm', ['install'], { cwd: loc, shell: true }
      installAt root
      installAt path.join root, 'litexa'
      resolve()

  builder = require '@litexa/core/src/command-line/skill-builder'

  cleanTempDirectories()
  .then ->
    installNPM()
  .then ->
    builder.build(root)
  .then (skill) ->
    skill.projectInfo.testRoot = path.join skill.projectInfo.root, '.test'
    mkdirp.sync skill.projectInfo.testRoot

    new Promise (resolve, reject) ->
      try
        js = skill.toLambda()
      catch err
        if err.location
          l = err.location
          err = new Error "
            #{l.source}[#{l.start.line}:#{l.start.column}]
            #{err.toString()}"
        return reject(err)

      # Let's run our tests on a 'show', so Display & APL are supported.
      skill.runTests {testDevice: 'show'}, (err, result) ->
        if err?
          return reject(err)
        unless result.success
          console.error l for l in result.log
          return reject new Error result.summary
        resolve(result)

  .then (result) ->
    cleanNPM()
    return result


exports.buildSkill = (lit) ->
  require('@litexa/core/src/parser/parserlib.coffee').__resetLib()
  skill = new Skill.Skill ProjectInfo.createMock()
  if typeof(lit) == 'string'
    skill.setFile "main.litexa", "default", lit + '\n'
  else
    for name, contents of lit
      [ filename, language ] = name.split '_'
      language = language ? 'default'
      unless filename.indexOf('.') > 0
        filename += ".litexa"
      skill.setFile filename, language, contents + '\n'
  return skill

exports.expectParse = (lit) ->
  try
    skill = exports.buildSkill lit
    skill.toModelV2 'en-US'
  catch err
    console.error "failed to parse: #{JSON.stringify lit}"
    throw err

exports.expectFailParse = (lit, errorMessageSubstring) ->
  try
    skill = exports.buildSkill lit
    skill.toModelV2 'en-US'
  catch err
    if errorMessageSubstring?
      unless err.message?.includes(errorMessageSubstring)
        throw new Error "Parse error message `#{err.message}`\ndid not contain text: #{errorMessageSubstring}"
    return

  throw new Error "Parse did not throw on: \n#{lit}"
