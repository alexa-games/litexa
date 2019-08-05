
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


program = require 'commander'
chalk = require 'chalk'
path = require 'path'
validator = require './optionsValidator'
GenerateCommandDirector = require './generateCommandDirector'
isp = require './isp'
projectClean = require './project-clean'

packageVersion = require('../../package.json').version

module.exports.run = ->

  root = process.cwd()

  program
    .version packageVersion
    .option '--no-color', 'disables print output coloring'
    .option '-r, --region [region]', 'execution region, e.g. en-US or de-DE', 'en-US'
    .option '-v, --verbose', 'verbose output'

  program
    .command 'model'
    .description "compiles a project's language model and prints it to the console."
    .action (cmd) ->
      chalk.enabled = cmd.parent.color
      options =
        root: root
        type: 'model'
        region: cmd.parent.region
      require('./printers.coffee').run options

  program
    .command 'handler'
    .description "compiles a project's JavaScript handler and prints it to the console."
    .action (cmd) ->
      chalk.enabled = cmd.parent.color
      options =
        root: root
        type: 'handler'
      require('./printers.coffee').run options

  program
    .command 'path [directory]'
    .description "prints the location of named paths within the current project."
    .option '-t --type [type]', "which path: root, litexa, or assets.", 'root'
    .option '-l --language [language]', "which language. Leave blank for the default language", 'default'
    .action (directory, cmd) ->
      errors = validator(
        cmd
        [
          {
            name: 'type'
            valid: [
              'root'
              'litexa'
              'assets'
            ]
            message: 'invalid "type" option. valid type options are: root, litexa, or assets.'
          }
        ]
      )

      errors.forEach (error) ->
        console.log chalk.red(error.message)

      directory = directory ? process.cwd()
      config = await require('./project-config.coffee').identifyConfigFileFromPath directory
      if config?
        root = path.dirname config
        if cmd.language == 'default'
          switch cmd.type
            when 'root'
              console.log root
            when 'litexa'
              console.log path.join root, 'litexa'
            when 'assets'
              console.log path.join root, 'litexa', 'assets'
            else
              console.error chalk.red("unknown path type #{cmd.type}")
        else
          switch cmd.type
            when 'root'
              console.log root
            when 'litexa'
              console.log path.join root, 'litexa', 'languages', cmd.language
            when 'assets'
              console.log path.join root, 'litexa', 'languages', cmd.language, 'assets'
            else
              console.error chalk.red("unknown path type #{cmd.type}")
      else
        console.error chalk.red("#{directory} does not appear to be in a litexa project")

  program
    .command 'deploy'
    .description "executes a deployment extension to push a skill project to the internet"
    .option '-d --deployment [deployment]', "which deployment to run, using the name from the deployments map in the Litexa configuration file.", 'development'
    .option '-t --type [type]', "what to deploy: all, assets, lambda, model or manifest.", 'all'
    .option '-w, --watch', "watch for file changes, then rerun deployment"
    .option '--no-cache', "disables local caching, used when the state of deployment is unknown and needs to be thoroughly verified"
    .action (cmd) ->
      errors = validator(
        cmd
        [
          {
            name: 'type'
            valid: [
              'all'
              'assets'
              'lambda'
              'model'
              'manifest'
            ]
            message: 'valid type options are [all, assets, lambda, model manifest].'
          }
        ]
      )

      errors.forEach (error) ->
        console.log chalk.red("unknown option value #{error.name} \"#{cmd[error.name]}\" :
          #{error.message}")

      process.exit(1) if errors.length > 0

      chalk.enabled = cmd.parent.color
      options =
        root: root
        deployment: cmd.deployment
        type: cmd.type
        watch: cmd.watch
        verbose: cmd.parent.verbose
        cache: cmd.cache
        coreVersion: packageVersion
      await require('./deploy.coffee').run options

  program
    .command 'test [filter]'
    .description "executes a project's tests and prints the output to the console."
    .option '--no-strict', 'disable strict testing'
    .option '--device [device]', 'which device to emulate (dot, echo, show)', 'show'
    .option '-w, --watch', "watch for file changes, then rerun tests"
    .action (filter, cmd) ->
      errors = validator(
        cmd
        [
          {
            name: 'device'
            valid: [
              'dot'
              'show'
              'echo'
            ]
            message: 'ignoring invalid device. valid device options are: dot, echo, show. defaulting to "show"'
          }
        ]
        true
      )

      errors.forEach (error) ->
        if error.name == 'device'
          cmd.type = 'show'
        console.log(chalk.yellow error.message)

      chalk.enabled = cmd.parent.color
      options =
        root: root
        filter: filter
        strict: cmd.strict
        region: cmd.parent.region
        watch: cmd.watch
        device: cmd.device
      require('./test.coffee').run options

  program
    .command 'generate [dir]'
    .alias 'init'
    .description "creates any missing required files for a litexa project."
    .option '-c, --config-language [configLanguage]', 'language of the generated configuration file, can be javascript, json, typescript, or coffee'
    .option '-s, --source-language [sourceLanguage]', 'language of the generated source code, can be javascript, typescript, or coffee'
    .option '-b, --bundling-strategy [bundlingStrategy]', 'the structure of the code layout as it pertains to litexa, can be webpack, npm-link, or none'
    .action (dir, cmd) ->
      errors = validator(
        cmd
        [
          {
            name: 'configLanguage'
            valid: [
              'javascript'
              'json'
              'typescript'
              'coffee'
            ]
            message: 'valid config languages are [javascript, json, typescript, coffee].'
          }
          {
            name: 'sourceLanguage'
            valid: [
              'javascript'
              'typescript'
              'coffee'
            ]
            message: 'valid source languages are [javascript, typescript, coffee].'
          }
          {
            name: 'bundlingStrategy'
            valid: [
              'none'
              'npm-link'
              'webpack'
            ]
            message: 'valid bundling strategies are [none, npm-link, webpack].'
          }
        ]
      )

      errors.forEach (error) ->
        console.log chalk.red("unknown option value #{error.name} \"#{cmd[error.name]}\" :
          #{error.message}")

      process.exit(1) if errors.length > 0

      guided = new GenerateCommandDirector({
        targetDirectory: dir
        selectedOptions: cmd
        availableOptions: [
          'configLanguage'
          'sourceLanguage'
          'bundlingStrategy'
        ]
      })

      selections = await guided.direct()

      chalk.enabled = cmd.parent.color
      options =
        root: root
        dir: path.join(root, selections.dir || '.')
        configLanguage: selections.configLanguage ? 'javascript'
        sourceLanguage: selections.sourceLanguage ? 'javascript'
        bundlingStrategy: selections.bundlingStrategy ? 'none'
      require('./generate.coffee').run options

  program
    .command 'logs'
    .description "retrieves runtime logs from a deployed skill."
    .option '-d --deployment [deployment]', "which deployment to pull logs from, using the name from the deployments map in the Litexa configuration file.", 'development'
    .action (cmd) ->
      chalk.enabled = cmd.parent.color
      options =
        root: root
        deployment: cmd.deployment
        region: cmd.parent.region
      require('./logs.coffee').run options

  program
    .command 'info'
    .description "prints out a litexa project's information block."
    .action (cmd) ->
      chalk.enabled = cmd.parent.color
      options =
        root: root
        region: cmd.parent.region
      try
        config = await (require('./project-config').loadConfig root)
        info = new (require('./project-info'))(config)
        console.log JSON.stringify info, null, 2
      catch err
        console.error err

  program
    .command 'pull [data]'
    .description "downloads specified data from the hosted skill via SMAPI. Currently supported for:
      isp (downloads remote in-skill products, and ovewrites local product files)"
    .option '-d --deployment [deployment]', "which deployment target to download specified data from, using the name from the deployments map in the Litexa configuration file.", 'development'
    .option '-s --stage [stage]', "stage for which to pull skill data (either development or live)", 'development'
    .action (data, cmd) ->
      options =
        root: root
        deployment: cmd.deployment
        stage: cmd.stage
        verbose: cmd.parent.verbose

      switch data
        when 'isp'
          try
            await isp.init options
            await isp.pullAndStoreRemoteProducts()
          catch err
            console.error chalk.red("failed to pull in-skill products")
        else
          console.error chalk.red("unknown data type '#{data}'. Currently supported data: isp")

  program
    .command 'push [data]'
    .description "pushes specified data from local to the hosted skill via SMAPI. Currently
      supports: isp (uploads local in-skill product files, and overrides remote products)"
    .option '-d --deployment [deployment]', "which deployment target to push specified data to, using the name from the deployments map in the Litexa configuration file.", 'development'
    .option '-s --stage [stage]', "stage for which to push skill data (either development or live)", 'development'
    .action (data, cmd) ->
      options =
        root: root
        deployment: cmd.deployment
        stage: cmd.stage
        verbose: cmd.parent.verbose

      switch data
        when 'isp'
          try
            await isp.init options
            await isp.pushLocalProducts()
          catch err
            console.error chalk.red("failed to push in-skill products")
        else
          console.error chalk.red("unknown data type '#{data}'. Currently supported data: isp")

  program
    .command 'reset [data]'
    .description "resets specified data from local to the hosted skill via SMAPI. Currently
      supports: isp (resets all in-skill products for testing)"
    .option '-d --deployment [deployment]', "which deployment target to reset specified data for, using the name from the deployments map in the Litexa configuration file.", 'development'
    .option '-s --stage [stage]', "stage for which to reset skill data (either development or live)", 'development'
    .action (data, cmd) ->
      options =
        root: root
        deployment: cmd.deployment
        stage: cmd.stage
        verbose: cmd.parent.verbose

      switch data
        when 'isp'
          try
            await isp.init options
            await isp.resetRemoteProductEntitlements()
          catch err
            console.error chalk.red("failed to reset in-skill product entitlements")
        else
          console.error chalk.red("unknown data type '#{data}'. Currently supported data: isp")

  program.on 'command:*', ->
    console.error """Invalid command: #{program.args.join(' ')}
      See --help for a list of available commands."""
    process.exit 1

  program.on '--help', ->
    console.log ""
    console.log "  For help on each command, pass --help to each, e.g. litexa test --help"
    console.log ""

  unless process.argv.slice(2).length
    program.outputHelp()

  await projectClean.run({root})
  program.parse process.argv
