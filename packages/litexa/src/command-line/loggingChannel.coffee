###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###
chalk = require 'chalk'
path = require 'path'
fs = require 'fs'
require '@src/getter.polyfill'
require '@src/setter.polyfill'

class LoggingChannel
  constructor: (@options) ->
    {
      logStream
      fileSystem
      logPrefix
      verbose
      includeRunningTime
      lastOutStreamTime
      lastFileTime
      startTime
      logFile
    } = @options

    @logStream = logStream ? console
    @fs = fileSystem || fs

    @logPrefix = if @hasPrefix then "[#{logPrefix}] " else ''
    @_verbose = verbose ? false
    @includeRunningTime = includeRunningTime ? true

    if @includeRunningTime
      @lastOutStreamTime = lastOutStreamTime || new Date()
      @lastFileTime = lastFileTime || new Date()
      @startTime = startTime || new Date()

    @fileLogStream = @options.fileLogStream
    @logFile = logFile

  # Public Interface
  write: ({format, line, now, writeCondition}) ->
    writeCondition ?= true

    args = {
      format
      data: line
      timeNow: now
    }

    @_write(Object.assign({
      writer: @logStream
      method: 'log'
      writeCondition: writeCondition and @canWriteToLogStream
      timeUpdated: 'lastOutStreamTime'
    }, args))

    args.format = null

    @_write(Object.assign({
      writer: @fileLogStream
      method: 'write'
      writeCondition: writeCondition and @canWriteToFileStream
      timeUpdated: 'lastFileTime'
      appendNewLine: true
    }, args))

  log: (line) ->
    @write({
      line
    })

  important: (line)  ->
    @write({
      line
      format: chalk.inverse
    })

  verbose: (line, obj) ->
    line = "#{line}: #{JSON.stringify(obj, null, 2)}" if obj
    @write({
      line,
      writeCondition: @_verbose
      format: chalk.gray
    })

  error: (line) ->
    @write({
      line
      format: chalk.red
    })

  warning: (line) ->
    @write({
      line
      format: chalk.yellow
    })

  # legacy interface (are these really the responsibility of the logger?)
  derive: (newPrefix) ->
    shallowCopy = Object.assign({}, @options)
    shallowCopy.logPrefix = newPrefix
    shallowCopy.fileLogStream = @fileLogStream
    new LoggingChannel(shallowCopy);

  runningTime: ->
    new Date() - @startTime

  # Private Methods
  _write: ({writer, method, writeCondition, timeUpdated, format, data, timeNow, appendNewLine}) ->
    format = identity unless format?
    timeNow = new Date() unless timeNow?

    if writeCondition
      deltaTime = undefined

      if @includeRunningTime
        deltaTime = timeNow - @[timeUpdated]
        @[timeUpdated] = timeNow

      formattedOutput = @_format({
        format
        logPrefix: @logPrefix
        time: deltaTime
        data,
        appendNewLine
      })
      writer[method](formattedOutput)

  _format: ({format, logPrefix, time, data, appendNewLine}) ->
    result = "#{logPrefix}"
    result += "+#{time}ms " if time?
    result += "#{data}"
    result = format result
    result += '\n' if appendNewLine

    result

  _createFileLogStream: ->
    return if @fileLogStream?
    @fileLogStream = @fs.createWriteStream @logFile, {flags :'w', encoding: 'utf8'}

  # Getters
  @getter 'hasPrefix', ->
    return @_hasPrefix if @_hasPrefix
    @_hasPrefix = @options.logPrefix? and typeof @options.logPrefix == 'string' and !!(@options.logPrefix.trim())

  @getter 'canWriteToFileStream', ->
    return @_canWriteToFileStream if @_canWriteToFileStream and (@_canWriteToFileStreamValid ? true)
    @_canWriteToFileStreamValid = true
    @_canWriteToFileStream = @logFile? and !!(@logFile.trim())

  @getter 'canWriteToLogStream', ->
    return @_canWriteToLogStream if @_canWriteToLogStream
    @_canWriteToLogStream = @logStream? and
      @logStream.hasOwnProperty('log') and
      typeof @logStream.log == 'function'

  @getter 'logFile', ->
    return @_logFile

  # Setters
  @setter 'logFile', (logFile) ->
    @_canWriteToFileStreamValid = false
    @_logFile = logFile
    @_createFileLogStream() unless not @canWriteToFileStream

  # Helper Methods
  identity = (x) -> x

module.exports = LoggingChannel
