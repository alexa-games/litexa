###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
    skill = await require('./skill-builder').build(options.root, options.deployment)
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
