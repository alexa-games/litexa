###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

class Generator
  constructor: (args) ->
    @options = args.options
    @logger = args.logger

  _rootPath: ->
    @options.dir || @options.root

  generate: ->
    throw new Error "#{this.constructor.name}#generate not implemented"

module.exports = Generator
