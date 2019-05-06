
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
