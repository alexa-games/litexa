
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


path = require 'path'
fs = require 'fs'
debug = require('debug')('litexa-assets')
{promisify} = require 'util'

readFilePromise = promisify fs.readFile


fileRegex = /(.*)\.wav$/i


module.exports = (options, lib) ->
  processor = {}

  # string name that will appear in logging
  processor.name = 'wav to mp3 converter'

  # in subsequent functions, info contains
  # * assetName: filename relative to project's /assets
  # * assetsRoot: source asset directory
  # * targetsRoot: target asset directory
  # * options: options block from the litexa config file

  # list what asset name(s) will be available in the
  # output, after this processor runs.
  # result should be an array of strings.
  processor.listOutputs = (info) ->
    match = info.assetName.match fileRegex
    if match == null
      return []

    converted = match[1] + '.mp3'
    return [ converted ]

  # process a single input asset
  # result should be a promise that will fire
  # once the conversion is complete, returning
  # the array of output asset names.
  processor.process = (info) ->
    exports.processFile( info, options )

  return
    assetPipeline: [ processor ]


exports.processFile = (info, options) ->
  options = options ? {}

  stream = require 'stream'
  wavDecoder = require 'wav-decoder'
  lame = require 'lame'
  logger = info.logger

  match = info.assetName.match /(.*)\.wav$/i

  # we just want a simple 1 to 1 transcode from
  # source to destination. We'll hash the source to
  # avoid spending time transcoding if the source
  # hasn't changed by storing the last converted hash
  # in a side by side file with the mp3.
  if info.source?
    source = info.source
  else
    source = path.join info.assetsRoot, info.assetName

  if info.destination?
    destination = info.destination
  else
    destination = path.join info.targetsRoot, match[1] + '.mp3'

  unless info.nocache
    cacheFilename = path.join info.targetsRoot, match[1] + '.wav.hash'
  sourceHash = null

  Promise.resolve()

  .then ->
    logger.log "converting #{source}"
    debug "loading #{info.assetName}"
    readFilePromise source

  .then (buffer) ->
    debug "decoding #{info.assetName}"

    # calculate hash of the current source file
    crypto = require 'crypto'
    hash = crypto.createHash 'sha1'
    hash.update buffer
    sourceHash = hash.digest('hex').toLowerCase().trim()

    try
      cachedKey = fs.readFileSync cacheFilename, 'utf8'
      if sourceHash == cachedKey
        # early out if we match the cache
        debug "cache was up to date for #{info.assetName}"
        return Promise.resolve()
    catch err
      debug "did not find #{info.assetName} in cache"

    # alright, continue with decoding
    wavDecoder.decode(buffer)
    .then (decoded) ->
      debug "encoding #{source}"
      new Promise (resolve, reject) ->
        channels = if decoded.channelData.length == 1 then 1 else 2
        if options.forceMono
          channels = 1

        # alexa SSML <audio/> supported format
        format =
          channels: channels
          sampleRate: decoded.sampleRate
          bitDepth: 32
          float: true
          endianness: 'LE'
          bitRate: 48
          outSampleRate: 24000

        format.mode = if format.channels == 2 then lame.STEREO else lame.MONO

        # interleave the buffers for lame if we need to
        if decoded.channelData.length == 1
          data = decoded.channelData[0]
        else
          data = new Float32Array decoded.length * 2
          for i in [0...decoded.length]
            data[i*2] = decoded.channelData[0][i]
            data[i*2+1] = decoded.channelData[1][i]

        pcmStream = new stream.PassThrough()
        pcmStream.end new Buffer(data.buffer)

        # run lame, collecting the results
        encoder = new lame.Encoder format
        encoder.on 'end', ->
          # write the source hash for next time
          unless info.nocache
            fs.writeFileSync cacheFilename, sourceHash, 'utf8'
          logger.log "converted #{info.assetName}"
          resolve()
        encoder.on 'error', ->
          reject err
        output = fs.createWriteStream destination
        output.on 'error', (err) ->
          reject err
        pcmStream.pipe(encoder).pipe(output)

module.exports.processFile = exports.processFile
