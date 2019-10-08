###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

{assert, expect} = require 'chai'
{match, spy, stub} = require 'sinon'

GenerateCommandDirector = require('@src/command-line/generateCommandDirector')

describe 'GenerateCommandDirector', ->
  targetDirectory = undefined
  selectedOptions = undefined
  availableOptions = undefined
  promptStub = undefined
  inquirer = undefined

  beforeEach ->
    targetDirectory = '.'
    selectedOptions = {
      configLanguage: 'javascript'
      sourceLanguage: 'json'
      bundlingStrategy: 'webpack'
      extraJunk: 'randomInput'
    }
    availableOptions = [
      'configLanguage'
      'sourceLanguage'
      'bundlingStrategy'
    ]
    inquirer = {
      prompt: () -> undefined
    }
    promptStub = stub(inquirer, 'prompt')

  describe '#direct', ->
    it 'returns a set of options that contains the values of the selected options based on available
      options and augments with target directory', ->
      director = new GenerateCommandDirector({
        targetDirectory
        selectedOptions
        availableOptions
        inputHandler: inquirer
      })

      options = await director.direct()

      expect(options).to.deep.equal({
        dir: '.'
        configLanguage: 'javascript'
        sourceLanguage: 'json'
        bundlingStrategy: 'webpack'
      })

    it 'does not prompt for a directory', ->
      promptStub.withArgs(match({name: 'language'})).returns({language: 'javascript'})
      promptStub.withArgs(match({name: 'bundlingStrategy'})).returns({bundlingStrategy: 'none'})
      director = new GenerateCommandDirector({
        targetDirectory
        selectedOptions: {}
        availableOptions
        inputHandler: inquirer
      })

      await director.direct()
      assert(promptStub.neverCalledWith(match({message: 'In which directory would you like to generate your project?'})), 'does not prompt for a directory')

    it 'prompts for the directory', ->
      promptStub.withArgs(match({name: 'targetDir'})).returns({targetDir: '.'})
      promptStub.withArgs(match({name: 'language'})).returns({language: 'javascript'})
      promptStub.withArgs(match({name: 'bundlingStrategy'})).returns({bundlingStrategy: 'none'})
      director = new GenerateCommandDirector({
        selectedOptions: {}
        availableOptions
        inputHandler: inquirer
      })

      await director.direct()

      assert(promptStub.calledWith(match({
        message: 'In which directory would you like to generate your project?'
      })), 'prompts for a directory')

    it 'prompts the user about language choice', ->
      promptStub.withArgs(match({name: 'targetDir'})).returns({targetDir: '.'})
      promptStub.withArgs(match({name: 'language'})).returns({language: 'javascript'})
      promptStub.withArgs(match({name: 'bundlingStrategy'})).returns({bundlingStrategy: 'none'})
      director = new GenerateCommandDirector({
        selectedOptions: {}
        availableOptions
        inputHandler: inquirer
      })

      await director.direct()

      assert(promptStub.calledWith(match({message: 'Which language do you want to write your code in?'})), 'prompts for a language')

    it 'prompts the user about code organization', ->
      promptStub.withArgs(match({name: 'targetDir'})).returns({targetDir: '.'})
      promptStub.withArgs(match({name: 'language'})).returns({language: 'javascript'})
      promptStub.withArgs(match({name: 'bundlingStrategy'})).returns({bundlingStrategy: 'none'})
      director = new GenerateCommandDirector({
        selectedOptions: {}
        availableOptions
        inputHandler: inquirer
      })

      await director.direct()

      assert(promptStub.calledWith(match({message: 'How would you like to organize your code?'})), 'prompts for a bundling strategy')

    it 'returns a set of options that contains the responses to the prompts', ->
      promptStub.withArgs(match({name:'targetDir'})).returns({targetDir: 'sample'})
      promptStub.withArgs(match({name:'language'})).returns({language: 'javascript'})
      promptStub.withArgs(match({name:'bundlingStrategy'})).returns({bundlingStrategy: 'none'})
      director = new GenerateCommandDirector({
        selectedOptions: {}
        availableOptions
        inputHandler: inquirer
      })

      options = await director.direct()

      expect(options).to.deep.equal({
        dir: 'sample'
        configLanguage: 'javascript'
        sourceLanguage: 'javascript'
        bundlingStrategy: 'none'
      })

    it 'returns a set options that contains the response to the prompts and the provided directory', ->
      promptStub.withArgs(match({name: 'targetDir'})).returns({targetDir: 'sample'})
      promptStub.withArgs(match({name: 'language'})).returns({language: 'javascript'})
      promptStub.withArgs(match({name: 'bundlingStrategy'})).returns({bundlingStrategy: 'none'})
      director = new GenerateCommandDirector({
        targetDirectory
        selectedOptions: {}
        availableOptions
        inputHandler: inquirer
      })

      options = await director.direct()

      expect(options).to.deep.equal({
        dir: '.'
        configLanguage: 'javascript'
        sourceLanguage: 'javascript'
        bundlingStrategy: 'none'
      })
