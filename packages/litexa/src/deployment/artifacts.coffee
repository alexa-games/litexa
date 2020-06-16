###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

fs = require 'fs'
path = require 'path'
util = require 'util'

readFilePromise = util.promisify fs.readFile

class Artifacts
  constructor: (@filename, @data) ->
    @data = @data ? {}
    unless 'variants' of @data
      @data.variants = {}
    unless 'globals' of @data
      @data.globals = {}

  setVariant: (@variant) ->
    unless @variant of @data.variants
      @data.variants[@variant] = {}
    unless 'versions' of @data.variants[@variant]
      @data.variants[@variant].versions = [ {} ]
    @currentVersion = @data.variants[@variant].versions.length - 1
    @variantInfo = @data.variants[@variant].versions[@currentVersion]

  save: (key, value) ->
    unless @variantInfo?
      throw "failed to set artifact because no variant is currently set"
    @variantInfo[key] = value
    @flush()

  delete: (key) ->
    unless @variantInfo?
      throw "failed to remove artifact because no variant is currently set"
    if @variantInfo[key]?
      delete @variantInfo[key]
      @flush()

  saveGlobal: (key, value) ->
    @data.globals[key] = value
    @flush()

  flush: ->
    if @filename
      fs.writeFileSync @filename, JSON.stringify(@data, null, 2), 'utf8'

  get: (key) ->
    unless @variantInfo?
      throw "failed to get artifact because no variant is currently set"
    @variantInfo[key]

  tryGet: (key) ->
    @variantInfo[key]

exports.Artifacts = Artifacts

exports.loadArtifacts = ({ context, logger }) ->
  filename = path.join context.projectRoot, 'artifacts.json'
  readFilePromise filename, 'utf8'
  .catch (err) ->
    if err.code == 'ENOENT'
      # that's fine, doesn't exist yet
      return Promise.resolve("{}")
    logger.error err
  .then (data) ->
    context.artifacts = new Artifacts filename, JSON.parse(data)
    context.artifacts.setVariant context.projectInfo.variant

    logger.verbose "loaded artifacts.json"
