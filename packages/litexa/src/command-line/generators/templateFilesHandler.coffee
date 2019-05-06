
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


fs = require 'fs'
path = require 'path'
Generator = require('./generator')

class TemplateFilesHandler
  constructor: (args) ->
    @logger = args.logger
    @resolvePath = args.syncPathResolver || path.join
    @readDir = args.syncDirectoryReader || fs.readdirSync
    @readFile = args.syncFileReader || fs.readFileSync
    @writeFile = args.syncFileWriter || fs.writeFileSync

  # Public Interface
  syncDir: ({
    sourcePaths
    destination
    whitelist = []
    dataTransform = (data) -> data
  }) ->
    for sourcePath in sourcePaths
      files = @_listFiles(sourcePath)

      for file in @_permit(whitelist, files)
        data = @_readFile(sourcePath, file)
        data = dataTransform(data)
        @_writeFile(destination, file, data)

  # "Private"  Methods
  _permit: (whitelist, files) ->
    files.filter (file) ->
      whitelist.reduce((acc, cur) ->
          match = ///^#{cur}///
          acc = acc || (file.search(match) > -1)
        false)

  _writeFile: (destination, filename, data) ->
    source = path.join destination, filename
    @writeFile source, "#{data}\n", 'utf8'
    @logger.log "created a default #{filename} file"

  _listFiles: (language) ->
    @readDir @resolvePath(__dirname, '../', 'templates', language)

  _readFile: (language, file) ->
    @readFile @resolvePath(__dirname, '../', 'templates', language, file), 'utf8'

module.exports = TemplateFilesHandler
