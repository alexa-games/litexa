###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

{assert, expect} = require('chai')

Test = require('@test/helpers')

DirectoryCreator = require('@src/command-line/generators/directoryCreator')
InlinedStructureCreator = require('@src/command-line/generators/directory/inlinedStructureCreator')
SeparateStructureCreator = require('@src/command-line/generators/directory/separateStructureCreator')
BundlerStructureCreator = require('@src/command-line/generators/directory/bundlerStructureCreator')

describe 'DirectoryCreator', ->
  describe '#constructor', ->
    options = undefined
    beforeEach ->
      loggerInterface = {
        log: () -> undefined
      }
      options = {
        bundlingStrategy: 'none'
        logger: loggerInterface
        litexaDirectory: 'litexa'
        templateFilesHandlerClass: Test.MockTemplateFilesHandlerInterface
      }

    it 'creates an inlined structure creator instance', ->
      creator = new DirectoryCreator(options)
      expect(creator).to.be.instanceOf(InlinedStructureCreator)

    it 'creates an separate structure creator instance', ->
      options.bundlingStrategy = 'npm-link'
      creator = new DirectoryCreator(options)
      expect(creator).to.be.instanceOf(SeparateStructureCreator)

    it 'creates an bundler structure creator instance', ->
      options.bundlingStrategy = 'webpack'
      creator = new DirectoryCreator(options)
      expect(creator).to.be.instanceOf(BundlerStructureCreator)

    it 'throws an error for an unsupported strategy', ->
      options.bundlingStrategy = 'unsupported'
      expect(() -> new DirectoryCreator(options)).to.throw()
