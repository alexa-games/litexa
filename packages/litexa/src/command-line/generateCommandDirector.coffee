###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

inquirer = require 'inquirer'

class GenerateCommandDirector
  constructor: (args) ->
    @targetDirectory = args.targetDirectory
    @selectedOptions = args.selectedOptions
    @availableOptions = args.availableOptions
    @inquirer = args.inputHandler || inquirer

  direct: ->
    options = {}

    selectedAtLeastOneOption = @availableOptions.reduce(@optionExists.bind(this), false)
    if selectedAtLeastOneOption
      options.dir = @targetDirectory
      @availableOptions.forEach ((option) ->
        options[option] = @selectedOptions[option]
      ).bind(this)
    else
      options.dir = if @targetDirectory then @targetDirectory else await @_inquireAboutTargetDirectory()
      language = await @_inqureAboutLanguageChoice()
      strategy = await @_inquireAboutCodeOrganization()

      options.configLanguage = language
      options.sourceLanguage = language
      options.bundlingStrategy = strategy

    options

  # "private methods"
  _inquireAboutTargetDirectory: ->
    result = await @inquirer.prompt({
      type: 'input'
      name: 'targetDir'
      message: 'In which directory would you like to generate your project?'
      default: '.'
    })
    result.targetDir

  _inqureAboutLanguageChoice: ->
    result = await @inquirer.prompt({
      type: 'list'
      name: 'language'
      message: 'Which language do you want to write your code in?'
      default: {
        value: 'javascript'
      }
      choices: [
        {
          name: 'JavaScript'
          value: 'javascript'
        }
        {
          name: 'TypeScript'
          value: 'typescript'
        }
        {
          name: 'CoffeeScript'
          value: 'coffee'
        }
      ]
    })
    result.language

  _inquireAboutCodeOrganization: ->
    result = await @inquirer.prompt({
      type: 'list'
      name: 'bundlingStrategy'
      message: 'How would you like to organize your code?'
      default: {
        value: 'none'
      }
      choices: [
        {
          name: 'Inlined in litexa. (useful for small projects with no dependencies)'
          value: 'none'
        }
        {
          name: "As modules. (useful for organizing code as npm packages)"
          value: 'npm-link'
        }
        {
          name: 'As an application. (useful if you have external dependencies)'
          value: 'webpack'
        }
      ]
    })
    result.bundlingStrategy

  optionExists:(exists, option) ->
    exists || @selectedOptions.hasOwnProperty(option)

module.exports = GenerateCommandDirector
