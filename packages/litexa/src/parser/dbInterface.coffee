
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


module.exports = class DBInterface
  constructor: ->
    @variables = {}
    @written = false
    @initialized = false

  isInitialized: ->
    @initialized

  initialize: ->
    @initialized = true

  read: (name) ->
    @variables[name]

  write: (name, value) ->
    @written = true
    @variables[name] = value

  finalize: (cb) ->
    setTimeout cb, 1
