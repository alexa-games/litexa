
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

source = process.argv[2]

unless source?
  console.log """
    This script converts a wav file into an Alexa SSML compatible MP3 file.

      coffee convert.coffee source [target]

    The first source argument should be the path to a wav file.

    Optionally the second target argument can specify the path where the mp3 should be saved. This defaults to the same location as the wav, with the extension swapped."""
  process.exit 0

unless path.isAbsolute source
  source = path.join process.cwd(), source
  source = path.normalize source
unless source.match /\.wav$/
  console.error "the first argument should be a wav filename"

try
  fs.statSync source
catch err
  console.error "couldn't seem to find the source file at #{source}"
  console.error err.toString()
  process.exit -1

console.log "source: #{source}"

target = process.argv[3]
unless target?
  target = source.replace '.wav', '.mp3'

unless path.isAbsolute target
  target = path.join process.cwd(), target
  target = path.normalize target

console.log "target: #{target}"

require('./litexa.extension.coffee').processFile
  assetName: path.parse(source).base
  source: source
  destination: target
  nocache: true
  logger: console
