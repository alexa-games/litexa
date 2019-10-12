###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

lib = module.exports.lib = {}

class lib.ParserError extends Error
  constructor: (@location, @message) ->
    super()
    @isParserError = true


lib.formatLocationStart = (location) ->
  unless location?
    return "unknown location"
  l = location
  if l.source? and l.start?.line? and l.start?.offset?
    "#{l.source}[#{l.start.line}:#{l.start.column}]"
  else if l.start?.line? and l.start.offset?
    "unknownFile[#{l.start.line}:#{l.start.column}"
  else if l.source?
    "#{l.source}[?:?]"
  else
    "unknown location"
