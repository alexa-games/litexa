
###

 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved.
 * These materials are licensed as 'Restricted Program Materials' under the Program Materials
 * License Agreement (the 'Agreement') in connection with the Amazon Alexa voice service.
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html.
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized
 * terms not defined in this file have the meanings given to them in the Agreement.
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

###

{assert} = require 'chai'
{assert: sinonAssert, match, spy, stub} = require 'sinon'
rimraf = require 'rimraf'

LoggingChannel = require('@src/command-line/loggingChannel')

describe 'LoggingChannel', ->
  logStream = undefined
  fileLogStream = undefined
  logSpy = undefined
  writeSpy = undefined
  logFile = 'test.log'
  fileSystem = {
    createWriteStream: () ->
  }

  beforeEach ->
    logStream = {
      log: () ->
    }
    fileLogStream = {
      write: () ->
    }
    logSpy = spy(logStream, 'log')
    writeSpy = spy(fileLogStream, 'write')

  describe '#writeToOutStream', ->
    it 'writes to output', ->
      output = 'informational'
      logger = new LoggingChannel({
        logStream
      })
      logger.write({line:output})
      sinonAssert.calledWithMatch(logSpy, match(///^\+[0-9]+ms\ #{output}$///))
      assert(writeSpy.notCalled, 'only writes to logStream (does not write to file)')

    it 'writes to output with logPrefix', ->
      logPrefix = 'LoggingChannelTest'
      output = 'informational'
      logger = new LoggingChannel({
        logPrefix
        logStream
      })
      logger.write({line:output})
      sinonAssert.calledWithMatch(logSpy, match(///^\[#{logPrefix}\]\ \+[0-9]+ms\ #{output}$///))
      assert(writeSpy.notCalled, 'only writes to logStream (does not write to file)')


    it 'applies format', ->
      format = spy()
      output = 'informational'
      logger = new LoggingChannel({
        logStream
        format
      })
      logger.write({line:output, format})
      sinonAssert.calledWithMatch(format, match.string)

    it 'it updates lastOutStreamTime', ->
      unixEpoch = Date.parse('01 Jan 1970 00:00:00 GMT')
      output = 'informational'
      logger = new LoggingChannel({
        logStream
      })
      logger.write({line:output, now: unixEpoch})
      lastOutStreamTime = logger['lastOutStreamTime']
      assert(lastOutStreamTime == unixEpoch, 'updated lastOutStreamTime')

    it 'does not include a running time', ->
      output = 'informational'
      logger = new LoggingChannel({
        logStream
        includeRunningTime: false
      })
      logger.write({line:output})
      sinonAssert.calledWithMatch(logSpy, match(///^#{output}$///))

  describe '#writeToFile', ->
    it 'writes to a file', ->
      output = 'informational'
      logger = new LoggingChannel({
        logStream
        logFile
        fileSystem
      })
      logger['fileLogStream'] = fileLogStream
      logger.write({line:output})
      sinonAssert.calledWithMatch(writeSpy, match(///^\+[0-9]+ms\ #{output}\n$///))

    it 'writes to a file with logPrefix', ->
      logPrefix = 'LoggingChannelTest'
      output = 'informational'
      logger = new LoggingChannel({
        logStream
        logPrefix
        logFile
        fileSystem
      })
      logger['fileLogStream'] = fileLogStream
      logger.write({line:output})
      sinonAssert.calledWithMatch(writeSpy, match(///^\[#{logPrefix}\]\ \+[0-9]+ms\ #{output}\n$///))

    it 'does not write to the file when it does not have a file to write to', ->
      output = 'informational'
      logger = new LoggingChannel({
        logStream
        logFile: ' '
      })
      logger['fileLogStream'] = fileLogStream
      logger.write({line:output})
      assert(writeSpy.notCalled, 'does not write to file')
      writeSpy.resetHistory()

      output = 'informational'
      logger = new LoggingChannel({
        logStream
        logFile: ''
        verbose: false
      })
      logger['fileLogStream'] = fileLogStream
      logger.write({line:output})
      assert(writeSpy.notCalled, 'does not write to file')
      writeSpy.resetHistory()

      output = 'informational'
      logger = new LoggingChannel({
        logStream
        logFile: null
        verbose: false
      })
      logger['fileLogStream'] = fileLogStream
      logger.write({line:output})
      assert(writeSpy.notCalled, 'does not write to file')
      writeSpy.resetHistory()

      output = 'informational'
      logger = new LoggingChannel({
        logStream
        logFile: undefined
        verbose: false
      })
      logger['fileLogStream'] = fileLogStream
      logger.write({line:output})
      assert(writeSpy.notCalled, 'does not write to file')
      writeSpy.resetHistory()

    it 'applies format', ->
      format = spy()
      output = 'informational'
      logger = new LoggingChannel({
        logStream
        logFile
        fileSystem
      })
      logger['fileLogStream'] = fileLogStream
      logger.write({line:output, format})
      sinonAssert.calledWithMatch(format, match.string)

    it 'updates lastFileTime', ->
      unixEpoch = Date.parse('01 Jan 1970 00:00:00 GMT')
      output = 'informational'
      logger = new LoggingChannel({
        logStream
        logFile
        fileSystem
      })
      logger['fileLogStream'] = fileLogStream
      logger.write({line:output, now: unixEpoch})
      lastFileTime = logger['lastFileTime']
      assert(lastFileTime == unixEpoch, 'updated lastFileTime')

    it 'does not include runningTime', ->
      output = 'informational'
      logger = new LoggingChannel({
        logStream
        logFile
        fileSystem
        includeRunningTime: false
      })
      logger['fileLogStream'] = fileLogStream
      logger.write({line:output})
      sinonAssert.calledWithMatch(writeSpy, match(///^#{output}\n$///))

    it 'allows for writing to a file, to be set at a later time', ->
      output = 'informational'
      logger = new LoggingChannel({
        logStream
      })
      logger.write({line:output})
      assert(writeSpy.notCalled, 'only writes to logStream (does not write to file)')

      logger.logFile = logFile
      assert(logger['fileLogStream'], 'FileLogStream Created')
      rimraf.sync(logFile)

      logger['fileLogStream'] = fileLogStream
      logger.write({line:output})
      sinonAssert.calledWithMatch(writeSpy, match(///^\+[0-9]+ms\ #{output}\n$///))

  describe '#log', ->
    it 'calls write with the appropriate args', ->
      output = 'informational'
      logger = new LoggingChannel({
        logStream
      })
      writeStub = stub(LoggingChannel.prototype, 'write').callsFake(-> true)
      logger.log(output)
      writeStub.restore();
      sinonAssert.calledWithMatch(writeStub, {line: output})

  describe '#important', ->
    it 'calls write with the appropriate args', ->
      output = 'informational'
      logger = new LoggingChannel({
        logStream
      })
      writeStub = stub(LoggingChannel.prototype, 'write').callsFake(-> true)
      logger.important(output)
      writeStub.restore();
      sinonAssert.calledWithMatch(writeStub, {line: output, format: match.func})

  describe '#verbose', ->
    it 'calls write with the appropriate args', ->
      output = 'informational'
      logger = new LoggingChannel({
        logStream
      })
      writeStub = stub(LoggingChannel.prototype, 'write').callsFake(-> true)
      logger.verbose(output)
      writeStub.restore();
      sinonAssert.calledWithMatch(writeStub, {line: output, format: match.func})

    it 'does not write to output in non-verbose mode', ->
      output = 'informational'
      logger = new LoggingChannel({
        logStream
        verbose: false
      })
      logger.verbose({line:output})
      assert(logSpy.notCalled, 'does not write to output stream in non-verbose mode')

    it 'does not write to the file in non-verbose mode', ->
      output = 'informational'
      logger = new LoggingChannel({
        logStream
        logFile
        fileSystem
        verbose: false
      })
      logger['fileLogStream'] = fileLogStream
      logger.verbose({line:output})
      assert(writeSpy.notCalled, 'does not write to file in non-verbose mode')

  describe '#error', ->
    it 'calls write with the appropriate args', ->
      output = 'informational'
      logger = new LoggingChannel({
        logStream
      })
      writeStub = stub(LoggingChannel.prototype, 'write').callsFake(-> true)
      logger.error(output)
      writeStub.restore();
      sinonAssert.calledWithMatch(writeStub, {line: output, format: match.func})

  describe '#warning', ->
    it 'calls write with the appropriate args', ->
      output = 'informational'
      logger = new LoggingChannel({
        logStream
      })
      writeStub = stub(LoggingChannel.prototype, 'write').callsFake(-> true)
      logger.warning(output)
      sinonAssert.calledWithMatch(writeStub, {line: output, format: match.func})
      writeStub.restore();
