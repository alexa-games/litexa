###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
peg = require 'pegjs'
crypto = require 'crypto'
debug = require('debug')('litexa')

sourceFilename = "#{__dirname}/litexa.pegjs"
cacheFilename = "#{__dirname}/litexa.pegjs.cached"
parserSourceCode = null

try
  hash = crypto.createHash('md5')
  sourcePEG = fs.readFileSync sourceFilename, 'utf8'
  hash.update(sourcePEG)
  sourceHash = hash.digest('hex')

  cached = JSON.parse(fs.readFileSync(cacheFilename, 'utf8'))
  if cached.hash == sourceHash
    parserSourceCode = cached.source
    debug "cached parser loaded"
  else
    debug "cached parser was state #{sourceHash} != #{cached.hash}"
catch e
  debug "no cached parser found"
  debug e

unless parserSourceCode
  source = fs.readFileSync(sourceFilename, 'utf8')
  parserSourceCode = peg.generate source, { cache: true, output: 'source', format: 'bare', allowedStartRules:['start', 'TestStatements'] }
  cached =
    hash: sourceHash
    source: parserSourceCode
  fs.writeFileSync cacheFilename, JSON.stringify(cached, null, 2), 'utf8'

try
  parser = eval(parserSourceCode)
catch e
  debug "failed to eval parser"
  throw e

module.exports.parser = parser
module.exports.sourceCode = parserSourceCode

module.exports.buildExtendedParser = (projectInfo) ->
  enableParserCache = false

  if projectInfo.isMock
    enableParserCache = false

  # try to load the cache
  if enableParserCache
    tempdir = path.join projectInfo.root, '.deploy'
    mkdirp.sync tempdir
    projectSourceCacheFilename = path.join tempdir, 'extended-litexa.pegjs'
    projectCodeCacheFilename = path.join tempdir, 'extended-litexa.pegjs.cached'
    try
      extParserSource = fs.readFileSync projectCodeCacheFilename, 'utf8'
      extParser = eval extParserSource
      return extParser

  # interpolate in any extensions
  extSourcePEG = "" + sourcePEG
  statementNames = []
  testStatementNames = []
  intentStatementNames = []

  for extensionName, extension of projectInfo.extensions
    continue unless extension.language?

    for statementName, statement of extension.language.statements
      statementNames.push statementName
      unless statement.parser?
        throw new Error "Statement #{statementName} in extension
          #{extensionName} is missing parser code"
      extSourcePEG += "\n#{statement.parser}\n"

    for statementName, statement of extension.language.testStatements
      testStatementNames.push statementName
      unless statement.parser?
        throw new Error "Test statement #{statementName} in extension #{extensionName} is missing parser code"
      extSourcePEG += "\n#{statement.parser}\n"

  replacePlaceholder = (placeholder, nameList) ->
    block = for s in nameList
      "  / " + s
    extSourcePEG = extSourcePEG.replace placeholder, block.join '\n'

  replacePlaceholder "  /* ADDITIONAL STATEMENTS */", statementNames
  replacePlaceholder "  /* ADDITIONAL TEST STATEMENTS */", testStatementNames
  replacePlaceholder "  /* ADDITIONAL INTENT STATEMENTS */", intentStatementNames

  # save the combined parser input for later
  if enableParserCache
    fs.writeFileSync projectSourceCacheFilename, extSourcePEG, 'utf8'

  extParserSource = peg.generate extSourcePEG, { cache: true, output: 'source', format: 'bare', allowedStartRules:['start', 'TestStatements', 'AllFileExclusions'] }

  try
    extParser = eval extParserSource
  catch err
    debug "failed to eval extended parser"
    throw e

  # success! Recycle the generated parser for later
  if enableParserCache
    fs.writeFileSync projectCodeCacheFilename, extParserSource, 'utf8'
  return extParser


fragmentParser = null
module.exports.parseFragment = (fragment, language) ->
  unless fragmentParser?
    source = fs.readFileSync sourceFilename, 'utf8'
    fragmentParserSource = peg.generate source,
      cache: true
      output: 'source'
      format: 'bare'
      allowedStartRules:['Fragment']
    fragmentParser = eval(fragmentParserSource)

  result = null

  skill =
    pushCode: (thing) -> result = thing
    getExtensions: -> {}

  fragmentParser.parse fragment,
    skill: skill
    lib: require './parserlib.coffee'
    language: language ? 'default'

  return result
