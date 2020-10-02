###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
    filterList = []
    dataTransform = (data) -> data
  }) ->
    for sourcePath in sourcePaths
      files = @_listFiles(sourcePath)

      for file in @_permit(filterList, files)
        data = @_readFile(sourcePath, file)
        data = dataTransform(data)
        @_writeFile(destination, file, data)

  # "Private"  Methods
  _permit: (filterList, files) ->
    files.filter (file) ->
      filterList.reduce((acc, cur) ->
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
