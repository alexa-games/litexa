
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


debug = require('debug')('litexa')
fs = require('fs')
path = require('path')
{PNG} = require('pngjs')
Generator = require('./generator')

class SkillIconsGenerator extends Generator
  @description: 'skill icons'

  constructor: (args) ->
    super(args)

  generate: ->
    @_ensureIcon 108
    @_ensureIcon 512

    Promise.resolve()

  # "Private" Methods
  _destination: ->
    path.join @_rootPath(), 'litexa', 'assets'

  _ensureIcon: (size) ->
    name = "icon-#{size}.png"
    filename = path.join @_destination(), name

    if fs.existsSync filename
      @logger.log "existing assets/#{name} found -> skipping creation"
      return

    # Create a red circle with a black outline
    png = {
      width: size
      height: size
      data: Buffer.alloc size * size * 4, 0xff
    }

    hh = size / 2
    t1 = Math.floor hh * 29 / 30
    debug "#{size} icon circle radius #{t1}"
    t2 = Math.floor t1 * 3 / 4
    t1 = t1 * t1
    t2 = t2 * t2
    for y in [0..size]
      yy = y - hh
      for x in [0..size]
        xx = x - hh
        r = xx * xx + yy * yy
        if r < t1 and r >= t2
          idx = (y * size + x) * 4
          png.data[idx] = 0
          png.data[idx + 1] = 0
          png.data[idx + 2] = 0
        else if r < t2
          idx = (y * size + x) * 4
          png.data[idx] = 255
          png.data[idx + 1] = 100
          png.data[idx + 2] = 100

    # Write it
    buffer = PNG.sync.write png, {}
    fs.writeFileSync filename, buffer

module.exports = SkillIconsGenerator
