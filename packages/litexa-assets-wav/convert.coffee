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
