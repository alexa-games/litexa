
###

 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved.
 * These materials are licensed as "Restricted Program Materials" under the Program Materials
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service.
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html.
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized
 * terms not defined in this file have the meanings given to them in the Agreement.
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

###


###

  The project info object is a merge of the information derived
  from the project config file, and information scanned from the
  project data, like lists of asset and code files.

###

fs = require 'fs'
path = require 'path'
globalModulesPath = require('global-modules')
debug = require('debug')('litexa-project-info')
LoggingChannel = require './loggingChannel'

class ProjectInfo
  constructor: (jsonConfig, @variant, logger = new LoggingChannel({logPrefix: 'project info'})) ->
    @variant = @variant ? "development"
    for k, v of jsonConfig
      @[k] = v
    @litexaRoot = path.join @root, "litexa"
    debug "litexa root is #{@litexaRoot}"
    @logger = logger

    # Direct Public Side-Effect
    @parseDirectory jsonConfig

  parseDirectory: ->
    unless fs.existsSync(@litexaRoot) or @root == '--mockRoot'
      throw new Error "Cannot initialize ProjectInfo no litexa sub directory
        found at #{@litexaRoot}"

    # compiled summary of package/extension info, to be sent in each response
    packageInfo = require '../../package.json'
    @userAgent = "#{packageInfo.name}/#{packageInfo.version} Node/#{process.version}"

    @parseExtensions()

    debug "beginning languages parse"
    @languages = {}
    @languages.default = @parseLanguage(@litexaRoot, 'default')
    @languagesRoot = path.join @litexaRoot, 'languages'
    if fs.existsSync @languagesRoot
      filter = (f) =>
        fullPath = path.join @languagesRoot, f
        return false unless fs.lstatSync(fullPath).isDirectory()
        return false if f[0] == '.'
        return true
      languages = ( f for f in fs.readdirSync(@languagesRoot) when filter(f) )
      for lang in languages
        @languages[lang] = @parseLanguage(path.join(@languagesRoot, lang), lang)

  parseExtensions: ->
    @extensions = {}
    @extensionOptions = @extensionOptions ? {}

    return if @root == '--mockRoot'

    lib = require '../parser/parserlib.coffee'

    deployModules = path.join @litexaRoot, 'node_modules'

    scanForExtensions = (modulesRoot) =>
      debug "scanning for extensions at #{modulesRoot}"
      # this is fine, no extension modules to scan
      return unless fs.existsSync modulesRoot

      for moduleName in fs.readdirSync modulesRoot
        if moduleName.charAt(0) == '@'
          scopePath = path.join modulesRoot, moduleName
          for scopedModule in fs.readdirSync scopePath
            scopedModuleName = path.join moduleName, scopedModule
            scanModuleForExtension(scopedModuleName, modulesRoot)
        else
          scanModuleForExtension(moduleName, modulesRoot)

    scanModuleForExtension = (moduleName, modulesRoot) =>
      if @extensions[moduleName]
        # this extension was already loaded - ignore duplicate
        # (probably installed locally as well as globally)
        return

      modulePath = path.join modulesRoot, moduleName
      debug "looking in #{modulePath}"

      # attempt to load any of the supported types
      found = false
      extensionFile = ""
      for type in ['coffee', 'js']
        extensionFile = path.join modulePath, "litexa.extension.#{type}"
        debug extensionFile
        if fs.existsSync extensionFile
          found = true
          break

      # fine, this is not an extension module
      unless found
        debug "module #{moduleName} did not contain litexa.extension.js/coffee,
          skipping for extensions"
        return

      debug "loading extension `#{moduleName}`"
      # add extension name and version to userAgent, to be included in responses
      try
        extensionPackageInfo = require path.join modulePath, 'package.json'
        @userAgent += " #{moduleName}/#{extensionPackageInfo.version}"
      catch err
        console.warn "WARNING: Failed to load a package.json for the extension module at
          #{modulePath}/package.json, while looking for its version number. Is it missing?"

      extension = require extensionFile
      extension.__initialized = false
      extension.__location = modulesRoot
      extension.__deployable = modulesRoot == deployModules

      options = @extensionOptions[moduleName] ? {}

      @extensions[moduleName] = extension options, lib
      if @extensions[moduleName].language?.lib?
        for k, v of @extensions[moduleName].language.lib
          if k of lib
            throw new Error "extension `#{moduleName}` wanted to add type `#{k}` to lib, but it was
              already there. That extension is unfortunately not compatible with this project."
          lib[k] = v

    scanForExtensions(x) for x in [
      deployModules
      path.join @root, 'node_modules'
      path.join @root, 'modules'
      globalModulesPath
    ]

  parseLanguage: (root, lang) ->
    debug "parsing language at #{root}"
    def =
      assetProcessors: {}
      convertedAssets:
        root: path.join @root, '.deploy', 'converted-assets', lang
        files: []
      assets:
        root: path.join root, 'assets'
        files: []
      code:
        root: root
        files: []

    return if @root == '--mockRoot'

    fileBlacklist = [
      'package.json'
      'package-lock.json'
      'tsconfig.json'
      'tslint.json'
      'mocha.opts'
      '.DS_Store'
    ]

    # collect all the files in the litexa directory
    # as inputs for the litexa compiler
    codeExtensionsWhitelist = [
      '.litexa'
      '.coffee'
      '.js'
      '.json'
    ]

    codeFilter = (f) ->
      fullPath = path.join def.code.root, f
      return false unless fs.lstatSync(fullPath).isFile()
      return false if f[0] == '.'
      extension = path.extname f
      return false unless extension in codeExtensionsWhitelist
      return true
    def.code.files = ( f for f in fs.readdirSync(def.code.root) when codeFilter(f) )

    assetExtensionsWhitelist = [
      '.png'
      '.jpg'
      '.mp3'
      '.json'
      '.jpeg'
      '.txt'
    ]

    for kind, info of @extensions
      continue unless info.assetPipeline?
      for proc, procIndex in info.assetPipeline
        # @TODO: Validate processor here?

        # Create a clone of our processor, so as not to override previous languages' inputs/outputs.
        clone = {}
        Object.assign(clone, proc)

        name = clone.name ? "#{kind}[#{procIndex}]"

        unless clone.listOutputs?
          throw new Error "asset processor #{procIndex} from extension #{kind} doesn't
            have a listOutputs function."

        def.assetProcessors[name] = clone
        clone.inputs = []
        clone.outputs = []
        clone.options = @plugins?[kind]

    # collect all the assets
    if fs.existsSync def.assets.root

      # we support direct copy for some built in types
      logger = @logger
      assetFilter = (f) ->
        fullPath = path.join def.assets.root, f
        return false unless fs.lstatSync(fullPath).isFile()
        return false if f[0] == '.'
        extension = path.extname f
        unless extension in assetExtensionsWhitelist
          return false
        return true

      def.assets.files = []

      for f in fs.readdirSync(def.assets.root)
        continue if f in fileBlacklist

        processed = false
        if assetFilter(f)
          def.assets.files.push f
          processed = true

        # check whether any extensions would produce
        # usable assets from this file
        for kind, proc of def.assetProcessors
          outputs = proc.listOutputs
            assetName: f
            assetsRoot: def.assets.root
            targetRoot: null
            options: proc.options

          if outputs?.length > 0
            debug "#{kind}: #{f} -> #{outputs}"
            processed = true
            proc.inputs.push f
            for o in outputs
              proc.outputs.push o
              if (o in def.assets.files) or (o in def.convertedAssets.files)
                throw new Error "Asset processor #{kind} would
                  produce a duplicate file #{o}.
                  Please resolve this before continuing by either
                  deleting the duplicate or determining whether you
                  have multiple asset processors that create
                  the same output."
              def.convertedAssets.files.push o

        unless processed
          logger.warning "Unsupported internally or by extensions, skipping asset: #{f}"


    debug "project info: \n #{JSON.stringify def, null, 2}"
    return def

  filesForLanguage: (lang) ->
    result = {}
    for type, info of @languages.default
      list = result[type] = {}
      for name in info.files
        list[name] = path.join info.root, name
    if lang of @languages
      for type, info of @languages[lang]
        list = result[type]
        for name in info.files
          list[name] = path.join info.root, name
    result

ProjectInfo.createMock = ->
  config = {
    root: "--mockRoot"
    name: "mockProject"
    isMock: true
  }
  return new ProjectInfo config, "mockTesting"

module.exports = ProjectInfo
