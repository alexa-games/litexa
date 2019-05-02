fs = require 'fs'
path = require 'path'
Generator = require('./generator')

class ArtifactTrackerGenerator extends Generator
  @description: 'artifacts tracker'

  constructor: (args) ->
    super(args)
    @artifactClass = args.artifactClass

  # Public Interface
  generate: ->
    filename = 'artifacts.json'
    source = path.join @_rootPath(), filename

    data =
      if fs.existsSync source
        @logger.log "existing #{filename} found -> skipping creation"
        JSON.parse fs.readFileSync source, 'utf8'
      else
        @logger.log "creating #{filename} -> contains deployment records and should be version
          controlled"
        {}

    artifacts = new @artifactClass source, data
    artifacts.saveGlobal 'last-generated', currentTime()

    # Direct Public Side-Effect
    @options.artifacts = artifacts

    return Promise.resolve()

  # Helper Methods
  currentTime = ->
    (new Date).getTime()

module.exports = ArtifactTrackerGenerator
