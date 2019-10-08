###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

# When used to type a database variable in Litexa,
# this class will be constructed only when the database
# value is still undefined. Otherwise, on subsequent
# skill requests, the database object will have its
# prototype patched back to this class each time.

class Game
  constructor: ->
    console.log "Constructed game"
    @score = 0
    @constructed = @constructed ? 0
    @constructed += 1

  greeting: ->
    "hello!"

  setFlag: (value) -> @flag = value
  getFlag: -> @flag ? false

  saveScore: (s) -> @score = s
  getScore: -> @score ? 0


WrapperPrototype =
  name: -> "#{@data.first} #{@data.last}"
  set: (f, l) ->
    @data.first = f
    @data.last = l

NameWrapper =
  Initialize: ->
    console.log "Initialized Name"
    first: "Bob"
    last: "Defaultson"

  Prepare: (value) ->
    wrapper = Object.create WrapperPrototype
    wrapper.data = value
    return wrapper
