
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


chalk = require 'chalk'
path = require 'path'
fs = require 'fs'
mkdirp = require 'mkdirp'

module.exports.run = (options, after) ->
  logger = options.logger ? console

  if logger.disableColor
    chalk.enabled = false

  error = (line) ->
    logger.log chalk.red line
    after(err) if after?

  try
    skill = await require('./skill-builder').build(options.root)
    switch options.type
      when 'model'
        model = skill.toModelV2 options.region ? 'default'
        logger.log JSON.stringify(model, null, 2)
      when 'handler'
        lambda = skill.toLambda()
        logger.log lambda
      else
        return error "unrecognized printer #{options.type}"
  catch err
    return error err
