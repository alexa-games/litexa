###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

InlinedStructureCreator = require('./directory/inlinedStructureCreator')
SeparateStructureCreator = require('./directory/separateStructureCreator')
BundlerStructureCreator = require('./directory/bundlerStructureCreator')
strategies = require('../bundlingStrategies')

class DirectoryCreator
  constructor: (args) ->
    strategy = args.bundlingStrategy

    args.templateFilesHandler = new args.templateFilesHandlerClass({
      logger: args.logger
    })

    switch strategies[strategy]
      when 'inlined' then return new InlinedStructureCreator(args)
      when 'separate' then return new SeparateStructureCreator(args)
      when 'bundled' then return new BundlerStructureCreator(args)
      else throw Error("Unsupported Bundling Strategy #{strategy}")

module.exports = DirectoryCreator
