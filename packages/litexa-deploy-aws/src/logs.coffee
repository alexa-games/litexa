
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


AWS = require 'aws-sdk'
fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
debug = require('debug')('litexa-logs')

exports.pull = (context, logger) ->
  require('./aws-config')(context, logger, AWS)

  # log group should be derivable from the project name and variant, via the lambda name
  # log stream is a little more difficult, basically we'll need to scan for all active ones

  globalParams =
    params:
      logGroupName: "/aws/lambda/#{context.projectInfo.name}_#{context.projectInfo.variant}_litexa_handler"

  context.cloudwatch = new AWS.CloudWatchLogs globalParams unless context.cloudwatch?

  debug "global params: #{JSON.stringify globalParams}"

  timeRange = 60 # minutes
  now = (new Date).getTime()
  logName = (new Date).toLocaleString()
  context.startTime = now - timeRange * 60 * 1000
  context.endTime = now

  listLogStreams context, logger
  .catch (error) ->
    if error.code == "ResourceNotFoundException"
      logger.log "no log records found for this skill yet"
      return Promise.resolve []
    return Promise.reject error
  .then (streams) ->
    promises = for stream in streams
      pullLogStream context, stream, logger

    Promise.all promises

  .then (streams) ->
    infos = []
    successes = 0
    fails = 0
    for stream in streams
      for id, info of stream
        infos.push info
        if info.success
          successes += 1
        else
          fails += 1

    infos.sort (a, b) -> b.start - a.start

    all = []
    all.push "requests: ✔ success:#{successes}, ✘ fail:#{fails}\n"

    for info in infos
      all = all.concat info.lines
      all.push '\n'

    variantLogsRoot = path.join context.logsRoot, context.projectInfo.variant
    mkdirp.sync variantLogsRoot
    logName = logName.replace(/\//g, '-')
    # WINCOMPAT: Windows cannot have '\/:*?"<>|' in the filename
    logName = logName.replace(/:/g, '.')
    filename = path.join variantLogsRoot, "#{logName}.log"
    fs.writeFileSync filename, all.join('\n'), 'utf8'
    logger.log "pulled #{filename}"

  .catch (error) ->
    debug "ERROR: #{JSON.stringify error}"
    logger.error error
    throw "failed to pull logs"


listLogStreams = (context, logger) ->
  params =
    orderBy: 'LastEventTime'
    descending: true
    #limit: 0
    #logStreamNamePrefix: 'STRING_VALUE'
    #nextToken: 'STRING_VALUE'

  debug "listing streams #{JSON.stringify params}"

  context.cloudwatch.describeLogStreams(params).promise()
  .then (data) ->
    streams = []
    debug "listed streams #{JSON.stringify data.logStreams}"
    for stream in data.logStreams
      if stream.lastEventTimestamp < context.startTime
        break
      streams.push stream.logStreamName
    Promise.resolve streams


pullLogStream = (context, streamName, logger) ->
  params =
    logStreamName: streamName
    startTime: context.startTime
    endTime: context.endTime
    # limit: 0 max
    # nextToken: 'STRING_VALUE'
    startFromHead: false

  debug "pulling log stream #{JSON.stringify params}"

  context.cloudwatch.getLogEvents(params).promise()
  .then (data) ->
    requests = {}

    idRegex = /RequestId: ([a-z0-9\-]+)/i
    keyRegex = /^([A-Z]+)( [A-Z]+)?/
    durationRegex = /Duration: ([0-9\.]+) ms/i
    memoryRegex = /Memory Used: ([0-9\.]+) MB/i
    id = null

    start = null
    for event in data.events

      match = event.message.match(idRegex)
      if match
        id = match[1]
        message = event.message.replace match[0], ''
      else
        parts = event.message.split '\t'
        if parts.length > 2
          time = (new Date parts[0]).toLocaleString()
          id = parts[1]
          message = parts[2..].join '\t'
        else
          message = event.message

      key = null
      type = null
      match = message.match keyRegex
      if match and match[0].length > 1
        key = match[1]
        type = match[2]?.trim()
        message = message.replace match[0], ''

      message = message.trim()

      header = null
      switch key
        when 'START'
          start = event.timestamp
          message = "--- ✘ #{time} [#{id[-8...]}] ---"
          failed = true
        when 'REPORT'
          # Duration: 205.58 ms	Billed Duration: 300 ms 	Memory Size: 256 MB	Max Memory Used: 65 MB
          match = message.match durationRegex
          duration = match?[1]
          match = message.match memoryRegex
          memory = match?[1]
          time = (new Date start).toLocaleString()
          if duration or memory
            marker = if failed then '✘' else '✔'
            header = "--- #{marker} #{time} #{duration}ms #{memory}MB [#{id[-8...]}] ---"
            message = null
        when 'VERBOSE'
          if type
            if type == 'RESPONSE'
              failed = false
            message = "#{type}: #{message}"
        else
          try
            message = JSON.stringify JSON.parse(message), null, 2
          if type
            message = "#{type}: #{message}"

      if message or header
        info = requests[id]
        unless info?
          info = requests[id] =
            start: event.timestamp
            lines: []
        if message
          info.lines.push message.trim()
        if header
          info.lines[0] = header.trim()
        info.success = not failed

    Promise.resolve requests
