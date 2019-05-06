
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


class Cache
  constructor: (@data, @filename) ->
    unless 'timestamps' of @data
      @data.timestamps = {}
    unless 'hashes' of @data
      @data.hashes = {}

  save: ->
    fs.writeFile @filename, JSON.stringify(@data, null, 2), 'utf8', (err) ->
      # don't care


  saveTimestamp: (name) ->
    unless name?
      throw new Error "bad timestamp name given to local cache"
    @data.timestamps[name] = (new Date).getTime()
    @save()

  millisecondsSince: (name) ->
    unless name of @data.timestamps
      return null
    return (new Date()).getTime() - @data.timestamps[name]

  longerThanSince: (name, seconds) ->
    # time checks are in minutes
    unless name of @data.timestamps
      return false

    delta = (new Date).getTime() - @data.timestamps[name]
    return (delta / 1000 / 60) > seconds

  lessThanSince: (name, seconds) ->
    unless name of @data.timestamps
      return false

    delta = (new Date).getTime() - @data.timestamps[name]
    return (delta / 1000 / 60) < seconds

  timestampExists: (name) ->
    return name of @data.timestamps

  storeHash: (name, hash) ->
    @data.hashes[name] = hash
    @save()

  getHash: (name) ->
    @data.hashes[name]

  hashMatches: (name, hash) ->
    @data.hashes[name] == hash


module.exports.loadCache = (context) ->
  cacheFilename = path.join context.deployRoot, 'local-cache.json'
  data = {}

  try
    data = JSON.parse fs.readFileSync cacheFilename, 'utf8'
  catch err
    # never mind

  unless context.cache
    data = {}

  context.localCache = new Cache data, cacheFilename
