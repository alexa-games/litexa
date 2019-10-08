###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
coffee = require 'coffeescript'
testing = require './testing.coffee'
{ ParserError, formatLocationStart } = require("./errors.coffee").lib

exp = module.exports
lib = exp.lib = require './parserlib.coffee'

makeReferenceTester = (litexaRoot, source) ->
  try
    # build a closure that can check for the existence of a symbol
    # within the main body of the inline code closure
    process.env.NODE_PATH = path.join litexaRoot, 'node_modules'
    require("module").Module._initPaths()
    func = eval """
      (function() {
        #{source}
        return (test) => eval("typeof(" + test + ") != 'undefined';");
      })();
    """
  catch err
    # complex code could die in that closure, and if it does we're
    # unable to validate local variable usage as they may be pointing
    # to a JavaScript variable
    console.error "warning: user code is either failing to compile,
      or is too complex for simple reference tester: #{err}.
      Variable names from code cannot be checked in Litexa."
    func = (test) -> true

  return func


Files = require './files.coffee'


class lib.Skill
  constructor: (@projectInfo) ->
    unless @projectInfo
      throw new Error "Cannot construct a skill without a project info"
    unless @projectInfo.name
      throw new Error "Cannot construct a skill without a name"
    @name = @projectInfo.name

    # might be a custom parser, if there are extensions
    @parser = null

    if window?.literateAlexaParser
      @parser = window.literateAlexaParser
    else
      litexaParser = require './parser.coffee'
      @parser = eval litexaParser.buildExtendedParser @projectInfo

    # cache these to customize the handler
    @extendedEventNames = {}
    for extensionName, extensionInfo of @projectInfo.extensions
      continue unless extensionInfo.compiler?.validEventNames?
      for eventName in extensionInfo.compiler?.validEventNames
        @extendedEventNames[eventName] = true
    @extendedEventNames = ( e for e of @extendedEventNames )

    # cache these for testing later
    @directiveValidators = {}
    for extensionName, extensionInfo of @projectInfo.extensions
      vals = extensionInfo.compiler?.validators?.directives ? {}
      for directiveName, validator of vals
        if directiveName of @directiveValidators
          v = @directiveValidators[directiveName]
          throw new Error "duplicate directive validator for the directive
            #{directiveName} found in both #{extensionName} and #{v.sourceExtension}"
        validator.sourceExtension = extensionName
        @directiveValidators[directiveName] = validator

    # sources
    @files = {}
    @languages =
      'default': {}
    @reparseLiterateAlexa()

  setFile: (filename, language, contents) ->
    language = language.toLowerCase()
    unless contents?
      console.log filename, language, contents
      throw new Error "probably missing language at skill set file" unless contents?

    unless contents?
      console.error "could not set contents of #{filename} to #{contents}"
      return

    if filename in ['config.json']
      # ignore these, they're used by the system not the skill
      return

    @languages[language] = {} unless language of @languages

    existingFile = @files[filename]
    if existingFile?
      existingFile.replaceContent language, contents
      return

    match = Files.infoFromFilename filename
    unless match?
      throw new Error "couldn't find extension in filename #{filename}"
    { category, name, extension } = match

    if name == 'skill'
      category = 'config'

    switch extension
      when "litexa"
        @files[filename] = new Files.LiterateAlexaFile name, language, "litexa", contents, category
        @files[filename].parsed = false
        @files[filename].dirty = true
      when "js"
        @files[filename] = new Files.JavaScriptFile name, language, extension, contents, category
      when "coffee"
        @files[filename] = new Files.CoffeeScriptFile name, language, extension, contents, category
      when "json"
        @files[filename] = new Files.JSONDataFile name, language, extension, contents, category
      else
        throw new Error "couldn't work out what to do with extension #{extension} in file #{filename}"

  getFileContents: (searchFilename, language) ->
    unless language of @languages
      language = @getLanguageForRegion(language)
    for filename, file of @files
      if filename == searchFilename
        return file.contentForLanguage(language)
    return null

  getExtensions: ->
    @projectInfo?.extensions ? {}

  createDefaultStates: ->
    result = {}
    result.launch = launch = new lib.State 'launch'
    result.global = global = new lib.State "global"

    pushCode = (target, line) ->
      line.location = { source: 'default state constructor', language: 'default' }
      target.pushCode line

    location =
    intent = global.pushOrGetIntent null, "AMAZON.StopIntent", null
    intent.defaultedResetOnGet = true
    pushCode intent, new lib.SetSkillEnd()

    intent = global.pushOrGetIntent null, "AMAZON.CancelIntent", null
    intent.defaultedResetOnGet = true
    pushCode intent, new lib.SetSkillEnd()

    intent = global.pushOrGetIntent null, "AMAZON.StartOverIntent", null
    intent.defaultedResetOnGet = true
    pushCode intent, new lib.Transition("launch", false)

    result.launch.resetParsePhase()
    result.global.resetParsePhase()

    return result


  reparseLiterateAlexa: ->
    # parsed parts
    @states = @createDefaultStates()
    @tests = {}
    @dataTables = {}
    @sayMapping = {}
    @dbTypes = {}
    @maxStateNameLength = 16

    for extensionName, extension of @projectInfo.extensions
      continue unless extension.statements?
      statements = extension.statements
      continue unless statements.lib?
      for k, v of statements.lib
        lib[k] = v

    for language of @languages
      # begin from the top of the state again each time
      for name, state of @states
        state.resetParsePhase()

      for name, file of @files
        if file.extension == 'litexa'
          try
            @parser.parse file.contentForLanguage(language), {
              lib: lib
              skill: @
              source: file.filename()
              language: language
            }
          catch err
            err.location = err.location ? {}
            err.location.source = name
            err.location.language = language
            throw err

    # now that we have all the states, validate connectivity
    stateNames = ( name for name of @states )
    for language of @languages
      for name, state of @states
        state.validateTransitions(stateNames, language)

    # check to see that every slot type is built in or defined
    # note, custom slots may be defined out of order, so we let
    # those slide until we get here
    for language of @languages
      context =
        skill: @
        language: language
        types: []

      customSlotTypes = []
      for name, state of @states
        state.collectDefinedSlotTypes(context, customSlotTypes)

      for name, state of @states
        state.validateSlotTypes(context, customSlotTypes)


  pushOrGetState: (stateName, location) ->
    unless stateName of @states
      @states[stateName] = new lib.State stateName

    for name of @states
      @maxStateNameLength = Math.max( @maxStateNameLength, name.length + 2 )

    state = @states[stateName]

    # a state may only exist once per language
    if state.locations[location.language]?
      throw new ParserError location, "a state named #{stateName} was already
        defined at #{formatLocationStart state.locations[location.language]}"

    # record this as the one
    state.locations[location.language] = location
    state.prepareForLanguage(location)

    # record the default location as primary
    if location.language == 'default'
      state.location = location
    return state

  pushIntent: (state, location, utterance, intentInfo) ->
    # scan for duplicates, we'll merge if we see them
    intent = state.pushOrGetIntent(location, utterance, intentInfo)
    for stateName, existingState of @states when existingState != state
      existingIntent = existingState.getIntentInLanguage(location.language, intent.name)
      if existingIntent? and not existingIntent.referenceIntent?
        intent.referenceIntent = existingIntent
        return intent
    return intent

  pushCode: (line) ->
    @startFunction = @startFunction ? new lib.Function
    @startFunction.lines.push(line)

  pushTest: (test) ->
    @tests[test.location.language] = @tests[test.location.language] ? []
    @tests[test.location.language].push test

  pushDataTable: (table) ->
    # todo name stomp?
    @dataTables[table.name] = table

  pushSayMapping: (location, source, target) ->
    if source of @sayMapping and @sayMapping[source] != target
      # TODO: support localized mappings
      console.error "duplicate pronounciation mapping for #{source} as #{target}, previously #{@sayMapping[source]}"
      #throw new ParserError location, "duplicate pronounciation mapping for #{source} as #{target}, previously #{@sayMapping[source]}"
    @sayMapping[source] = target

  pushDBTypeDefinition: (definition) ->
    if definition.name of @dbTypes
      old = @dbTypes[definition.name]
      throw new ParserError definition.location, "The db variable #{old.name} already has the
        previously defined type #{old.type}"

    @dbTypes[definition.name] = definition

  refreshAllFiles: ->
    litexaDirty = false
    for name, file of @files
      if file.extension == 'litexa' and file.dirty
        litexaDirty = true
        file.dirty = false
    if @projectInfoDirty
      litexaDirty = true
      @projectInfoDirty = false
    if litexaDirty
      @reparseLiterateAlexa()

  toSkillManifest: ->
    skillFile = @files['skill.json']
    unless skillFile?
      return "missing skill file"
    output = JSON.parse(JSON.stringify(skillFile.content))
    output.skillManifest?.apis?.custom?.endpoint?.uri = "arn"
    return JSON.stringify(output, null, 2)

  toLambda: (options) ->
    @refreshAllFiles()

    require('./sayCounter').reset()

    options = options ? {}
    @libraryCode = [
      "var litexa = exports.litexa;"
      "if (typeof(litexa) === 'undefined') { litexa = {}; }"
      "if (typeof(litexa.modulesRoot) === 'undefined') { litexa.modulesRoot = process.cwd(); }"
    ]

    if options.preamble?
      @libraryCode.push options.preamble
    else
      source = fs.readFileSync(__dirname + '/lambda-preamble.coffee', 'utf8')
      source = coffee.compile(source, {bare: true})
      @libraryCode.push source

    # some functions we'd like to allow developers to override
    @libraryCode.push "litexa.overridableFunctions = {"
    @libraryCode.push "  generateDBKey: function(identity) {"
    @libraryCode.push "    return `${identity.deviceId}`;"
    @libraryCode.push "  }"
    @libraryCode.push "};"

    librarySource = fs.readFileSync(__dirname + '/litexa-library.coffee', 'utf8')
    librarySource = coffee.compile(librarySource, {bare: true})
    @libraryCode.push librarySource

    source = fs.readFileSync(__dirname + '/litexa-gadget-animation.coffee', 'utf8')
    @libraryCode.push coffee.compile(source, {bare: true})

    @libraryCode.push @extensionRuntimeCode()

    @libraryCode.push "litexa.extendedEventNames = #{JSON.stringify @extendedEventNames};"


    @libraryCode = @libraryCode.join("\n")

    output = new Array

    output.push @libraryCode

    output.push "// END OF LIBRARY CODE"

    output.push "\n// version summary"
    output.push "const userAgent = #{JSON.stringify(@projectInfo.userAgent)};\n"

    output.push "litexa.projectName = '#{@name}';"
    output.push "var __languages = {};"
    for language of @languages
      output.push "__languages['#{language}'] = { enterState:{}, processIntents:{}, exitState:{}, dataTables:{} };"

    do =>
      output.push "litexa.sayMapping = ["
      lines = []
      for source, target of @sayMapping
        source = source.replace(/'/g, '\\\'')
        target = target.replace(/'/g, '\\\'')
        lines.push "  { test: new RegExp(' #{source}','gi'), change: ' #{target}' }"
        lines.push "  { test: new RegExp('#{source} ','gi'), change: '#{target} ' }"
      output.push lines.join ",\n"
      output.push "];"

    do =>
      output.push "litexa.dbTypes = {"
      lines = []
      for name, def of @dbTypes
        lines.push "  #{name}: { type: '#{def.type}' }"
      output.push lines.join ",\n"
      output.push "};"

    do =>
      shouldIncludeFile = (file) ->
        return false unless file.extension == 'json'
        return false unless file.fileCategory == 'regular'
        return true

      # write out the default language file data as
      # an inlined in memory cache
      output.push "var jsonSourceFiles = {}; "
      defaultFiles = []
      for name, file of @files
        continue unless shouldIncludeFile file
        continue unless file.content['default']?
        output.push "jsonSourceFiles['#{name}'] = #{JSON.stringify(file.content['default'], null, 2)};"
        defaultFiles.push name
      output.push "\n"

      output.push "__languages.default.jsonFiles = {"
      props = []
      for name in defaultFiles
        props.push "  '#{name}': jsonSourceFiles['#{name}']"
      output.push props.join ",\n"
      output.push "};\n"

      # each language is then either a pointer back
      # to the main cache, or a local override data block
      for language of @languages
        continue if language == 'default'
        files = {}
        for name, file of @files
          continue unless shouldIncludeFile file
          if language of file.content
            files[name] = JSON.stringify(file.content[language], null, 2)
          else if 'default' of file.content
            files[name] = true
        output.push "__languages['#{language}'].jsonFiles = {"
        props = []
        for name, data of files
          if data == true
            props.push "  '#{name}': jsonSourceFiles['#{name}']"
          else
            props.push "  '#{name}': #{data}"
        output.push props.join ",\n"
        output.push "};\n"

    #output.push "exports.dataTables = {};"

    source = fs.readFileSync(__dirname + '/handler.coffee', 'utf8')
    source = coffee.compile(source, {bare: true})
    output.push source

    for language of @languages
      options.language = language
      output.push "(function( __language ) {"
      output.push "var enterState = __language.enterState;"
      output.push "var processIntents = __language.processIntents;"
      output.push "var exitState = __language.exitState;"
      output.push "var dataTables = __language.dataTables;"
      output.push "var jsonFiles = __language.jsonFiles;"

      output.push @lambdaCodeForLanguage(language, output)

      do =>
        referenceSourceCode = "var litexa = {};\n"
        referenceSourceCode += librarySource + "\n"
        referenceSourceCode += @extensionRuntimeCode()
        referenceSourceCode += @testLibraryCodeForLanguage(language) + "\n"

        try
          # for pro debugging when you get the error about complexity, write
          # the contents of the reference tester to the .test directory
          mkdirp.sync path.join @projectInfo.root, '.test'
          fs.writeFileSync (path.join @projectInfo.root, '.test', 'referenceTester.js'), referenceSourceCode

        options.referenceTester = makeReferenceTester (path.join @projectInfo.root, 'litexa'), referenceSourceCode

      # inject code to map typed DB objects to their
      # types from inside this closure
      output.push "__language.dbTypes = {"
      output.push (for name, def of @dbTypes
        "  #{name}: #{def.type}").join(',\n')
      output.push "};"

      for name, state of @states
        state.toLambda output, options
      output.push "\n"

      for name, table of @dataTables
        table.toLambda output, options
      output.push "\n"

      output.push "})( __languages['#{language}'] );"
      output.push "\n"

    return output.join('\n')


  extensionRuntimeCode: ->
    return "" unless @projectInfo?
    code = []
    names = {}

    list = []
    for extensionName, extension of @projectInfo.extensions
      runtime = extension.runtime
      continue unless runtime?

      unless runtime.apiName?
        throw new Error "Extension `#{extensionName}` specifies it has a runtime
          component, but didn't provide an apiName key"
      apiName = runtime.apiName

      if runtime.apiName of names
        throw new Error "Extension `#{extensionName}` specifies a runtime
          component with the apiName `#{apiName}`, but that name
          is already in use by the `#{names[apiName]}` extension."

      names[apiName] = extensionName

      list.push "  // #{extensionName} extension"
      if runtime.require?
        list.push "  ref = require('#{runtime.require}')(context);"
      else if runtime.source?
        list.push "  ref = (#{runtime.source})(context);"
      else
        throw new Error "Extension `#{extensionName}` specified a runtime
          component, but provides neither require nor source keys."

      list.push "  #{apiName} = ref.userFacing;"
      list.push "  extensionEvents['#{extensionName}'] = ref.events;"
      list.push "  if (ref.requests) { extensionRequests['#{extensionName}'] = ref.requests; }"

    if list.length > 0
      code.push "// *** Runtime objects from loaded extensions"
      for name of names
        code.push "let #{name} = null;"
      code.push "\n"

    code.push "// *** Initializer functions from loaded extensions"
    code.push "let extensionEvents = {};"
    code.push "let extensionRequests = {};"
    code.push "function initializeExtensionObjects(context){"
    code.push "  let ref = null;"
    code.push list.join "\n"
    code.push "};"

    return code.join '\n'

  testLibraryCodeForLanguage: (language) ->
    output = []
    output.push "var jsonFiles = {};"
    for name, file of @files
      continue unless file.extension == 'json'
      continue unless file.fileCategory == 'regular'
      content = file.contentForLanguage(language)
      if content?
        output.push "jsonFiles['#{name}'] = #{JSON.stringify(content)};"
    output.push @lambdaCodeForLanguage language
    return output.join '\n'

  lambdaCodeForLanguage: (language) ->
    output = []
    appendFiles = (filter) =>
      for name, file of @files
        continue unless file.extension == filter
        continue unless file.fileCategory == 'regular'
        if file.exception?
          throw file.exception
        output.push file.rawForLanguage(language)

    appendFiles('js')
    jsCode = output.join '\n'
    output = []
    appendFiles('coffee')
    try
      allCode = output.join '\n'
      coffeeCode = coffee.compile allCode, { bare: true }
    catch err
      err.filename = 'allcoffee'

    return jsCode + '\n' + coffeeCode


  hasStatementsOfType: (types) ->
    for name, state of @states
      return true if state.hasStatementsOfType(types)
    return false

  collectRequiredAPIs: (apis) ->
    @refreshAllFiles()
    for name, state of @states
      state.collectRequiredAPIs?(apis)


  toUtterances: ->
    @refreshAllFiles()
    output = []
    for name, state of @states
      state.toUtterances output
    return output.join('\n')

  getLanguageForRegion: (region) ->
    throw new Error "missing region" unless region?
    language = region.toLowerCase()
    unless language of @languages
      language = language[0...2]
      if language == 'en'
        language = 'default'
      unless language of @languages
        language = 'default'
        message = "cannot find language for region #{region} in skill #{@name}, only have #{k for k of @languages}"
        if @strictMode
          throw new Error message
        else
          console.error message
    return language


  toModelV2: (region) ->
    @refreshAllFiles()

    unless region?
      throw new Error "missing region for toModelV2"

    language = @getLanguageForRegion(region)

    context =
      intents: {}
      language: language
      skill: @
      types: {}

    output =
      languageModel:
        invocationName: ""
        types: []
        intents: []

    for name, state of @states
      state.toModelV2 output, context

    for name, type of context.types
      output.languageModel.types.push type

    if output.languageModel.types.length == 0
      delete output.languageModel.types

    addRequiredIntents = (list) ->
      intentMap = {}
      for i in output.languageModel.intents
        intentMap[i.name] = true

      for i in list
        unless i of intentMap
          output.languageModel.intents.push { name: i }

    if @hasStatementsOfType ['music']
      # audio player required
      if true
        addRequiredIntents [
          "AMAZON.PauseIntent"
          "AMAZON.ResumeIntent"
        ]

      # audio player optional
      if false
        addRequiredIntents [
          "AMAZON.CancelIntent"
          "AMAZON.LoopOffIntent"
          "AMAZON.LoopOnIntent"
          "AMAZON.NextIntent"
          "AMAZON.PreviousIntent"
          "AMAZON.RepeatIntent"
          "AMAZON.ShuffleOffIntent"
          "AMAZON.ShuffleOnIntent"
        ]

      # display optional
      if false
        addRequiredIntents [
          "AMAZON.NavigateHomeIntent"
        ]

    # ??
    addRequiredIntents [ "AMAZON.StartOverIntent" ]

    # This one is required, and SMAPI will actually auto insert it
    addRequiredIntents [ "AMAZON.NavigateHomeIntent" ]

    invocation = @name.replace /[^a-zA-Z0-9 ]/g, ' '
    if @files['skill.json']
      read = @files['skill.json'].content.manifest.publishingInformation?.locales?[region]?.invocationName
      invocation = read if read?
    output.languageModel.invocationName = invocation.toLowerCase()
    return output

  hasIntent: (name, language) ->
    for n, state of @states
      return true if state.hasIntent name, language
    return false

  toLocalization: () ->
    @refreshAllFiles()
    result =
      states: {}
      intents: {}

    for name, state of @states
      state.toLocalization result

    return result


  runTests: (options, cb, tests) ->

    testContext = new lib.TestContext @, options

    testContext.litexaRoot = ''

    if @config?.root?
      #process.chdir @config.root
      testContext.litexaRoot = path.join @config.root, 'litexa'

    if @projectInfo?.root?
      testContext.litexaRoot = path.join @projectInfo.root, 'litexa'

    testContext.testRoot = path.join testContext.litexaRoot, '..', '.test'

    for k in ['abbreviateTestOutput', 'strictMode', 'testDevice']
      if options?[k]?
        @[k] = options[k]

    options.reportProgress = options.reportProgress ? () ->

    unless @abbreviateTestOutput?
      @abbreviateTestOutput = true

    testRegion = options.region ? 'en-US'
    testContext.language = @testLanguage = @getLanguageForRegion testRegion
    # test the language model doesn't have any errors
    languageModel = @toModelV2 testRegion

    # mock some things external to the handler
    db = new (require('./mockdb.coffee'))()
    testContext.db = db
    Entitlements = require './mockEntitlements.coffee'

    # for better error reporting, while testing prefer to have tracing on
    unless process.env.enableStateTracing?
      process.env.enableStateTracing = true

    # capture the lambda compilation
    exports = {}
    testContext.lambda = exports

    exports.litexa =
      assetsRoot: 'test://'
      localTesting: true
      localTestRoot: @projectInfo.testRoot
      localAssetsRoot: path.join testContext.litexaRoot, 'assets'
      modulesRoot: path.join testContext.litexaRoot
      reportProgress: options.reportProgress

    testContext.litexa = exports.litexa

    exports.executeInContext = (line) -> eval(line)

    try
      @lambdaSource = @toLambda({preamble: "", strictMode: options.strictMode})
      @lambdaSource += """
        escapeSpeech = function(line) {
          return ("" + line).replace(/ /g, '\u00A0');
        }
      """
    catch err
      console.error "failed to construct skill function"
      return cb err, { summary: err.stack }

    try
      process.env.NODE_PATH = path.join testContext.litexaRoot, 'node_modules'
      require("module").Module._initPaths()

      if @projectInfo?.testRoot?
        fs.writeFileSync (path.join @projectInfo.testRoot, 'test.js'), @lambdaSource, 'utf8'

      eval @lambdaSource
    catch err
      # see if we can catch the source
      # console.error err
      ###
        try
          Module = require 'module'
          tmp = new Module
          tmp._compile @lambdaSource, 'test.js'
        catch err2
          if err2.toString() == err.toString()
            console.error err2.stack
      ###
      return cb err, { summary: "Failed to bind skill function, check your inline code for errors." }

    Logging = exports.Logging
    Logging.log = ->
      console.log.apply console, arguments
    Logging.error = ->
      console.error.apply console, arguments
    exports.Logging = Logging

    # determine which tests to run
    remainingTests = []
    if tests
      remainingTests.push t for t in tests
    else
      focusTest = (testfilename, testname) ->
        return true unless options.focusedFiles?
        for f in options.focusedFiles
          if testfilename.indexOf(f) >= 0
            return true
          if testname and (testname.indexOf(f) >= 0)
            return true
        return false

      includedTests = {}
      if @testLanguage of @tests
        for test in @tests[@testLanguage]
          continue unless focusTest(test.sourceFilename, test.name)
          remainingTests.push test
          includedTests[test.sourceFilename] = true

      if @tests.default?
        for test in @tests['default']
          continue unless focusTest(test.sourceFilename, test.name)
          continue if includedTests[test.sourceFilename]
          remainingTests.push test

      for name, file of @files when file.isCode and file.fileCategory == 'test'
        test = new testing.lib.CodeTest file
        unless focusTest(file.filename(), null)
          test.filters = options.focusedFiles ? null
        remainingTests.push test

    # resolve dependent captures
    # if the focused tests rely on resuming state
    # from another test, then we need to pull them
    # into the list
    captureNeeds = {}
    captureHaves = {}
    for t in remainingTests
      if t.resumesNames?
        for n in t.resumesNames
          captureNeeds[n] = true
      if t.capturesNames?
        for n in t.capturesNames
          captureHaves[n] = true

    for need of captureNeeds
      unless need of captureHaves
        do =>
          if @testLanguage of @tests
            for test in @tests[@testLanguage]
              if test.capturesNames? and need in test.capturesNames
                captureHaves[need] = true
                remainingTests.push test
                return

          for test in @tests['default']
            if test.capturesNames? and need in test.capturesNames
              captureHaves[need] = true
              remainingTests.push test
              return

    do =>
      # order by capture dependency:
      # rebuild list by looping repeatedly through inserting,
      #  but only when capture dependency is already in list
      testCount = remainingTests.length
      presorted = remainingTests
      remainingTests = []
      savedNames = []
      for looping in [0...testCount]
        break if remainingTests.length == testCount
        for test in presorted
          ready = true
          if test.resumesNames
            for name in test.resumesNames
              ready = false unless name in savedNames
          if ready
            remainingTests.push test
            if test.capturesNames
              savedNames.push n for n in test.capturesNames
            test.capturesSorted = true
        presorted = ( t for t in presorted when not t.capturesSorted )

      unless remainingTests.length == testCount
        names = ( t.name for t in presorted )
        throw Error "Couldn't find states to resume for #{testCount - remainingTests.length} tests: #{JSON.stringify names}"

    testContext.collectAllSays()

    # accumulate output
    successes = 0
    fails = 0
    output = { log:[], cards:[], directives:[], raw:[] }

    unless options.singleStep
      output.log.push "Testing in region #{options.region}, language #{@testLanguage} out of #{JSON.stringify (k for k of @languages)}"

    for name, file of @files
      if file.exception?
        output.log.push "Error with file #{file.filename()}: #{file.exception}"

    # step through each test asynchronously
    testCounter = 1
    totalTests = remainingTests.length
    lastTimeStamp = new Date
    firstTimeStamp = new Date
    nextTest = =>
      if remainingTests.length == 0
        totalTime = new Date - firstTimeStamp
        options.reportProgress( "test steps complete #{testCounter-1}/#{totalTests} #{totalTime}ms total" )
        if fails
          output.summary = "✘ #{successes + fails} tests run, #{fails} failed (#{totalTime}ms)\n"
        else
          output.summary = "✔ #{successes} tests run, all passed (#{totalTime}ms)\n"
        unless options.singleStep
          output.log.unshift output.summary
        output.tallies =
          successes: successes
          fails: fails
        output.success = fails == 0
        cb null, output, testContext
        return

      testContext.db.reset()
      test = remainingTests.shift()

      options.reportProgress( "test step #{testCounter++}/#{totalTests} +#{new Date - lastTimeStamp}ms: #{test.name ? test.file?.filename()}" )
      lastTimeStamp = new Date

      test.test testContext, output, (err, successCount, failCount) =>
        successes += successCount
        fails += failCount
        if remainingTests.length > 0 and (successCount + failCount) > 0
         output.log.push "\n"
        nextTest()

    nextTest()

  resumeSingleTest: (testContext, test, cb) ->
    output = { log:[], cards:[], directives:[], raw:[] }

    try
      test.test testContext, output, (err, successCount, failCount) =>
        cb null, output
    catch err
      cb err, output

  reportIntents: (language) ->
    @refreshAllFiles()
    result = {}
    for name, state of @states
      state.reportIntents language, result
    return ( k for k of result )


reportError = (e, src, filename) ->
  if e.location?
    loc = e.location
    console.log "ERROR: #{filename}(#{loc.start?.line}:#{loc.start?.column}) "
    console.log e.message
    for line, lineno in src.split '\n'
      if Math.abs( lineno - loc.start.line ) < 2
        console.log "#{lineno+1} > #{line}"
      if lineno == loc.start.line - 1
        pad = 3 + "#{lineno+1}".length
        pad = (' ' for i in [0...pad]).join ''
        ind = pad + (' ' for i in [1...loc.start.column]).join('')
        ind += ('^' for i in [loc.start.column .. loc.end.column]).join('')
        console.log ind
  else
    console.error "parse error with no location"
    console.error e


exp.Skill = lib.Skill
exp.reportError = reportError
exp.parse = (text, filename, language, reportErrors) ->
  try
    skill = new lib.Skill
    dot = filename.lastIndexOf('.')
    skill.name = filename.substr(0, dot)
    skill.setFile filename, language, text
    return skill
  catch e
    if reportErrors
      reportError(e, text, filename)
    throw e
  return null
