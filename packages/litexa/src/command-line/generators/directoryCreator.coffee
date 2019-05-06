
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
