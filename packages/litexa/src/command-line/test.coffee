chalk = require 'chalk'
path = require 'path'
fs = require 'fs'
mkdirp = require 'mkdirp'
chokidar = require 'chokidar'


module.exports.run = (options) ->
  logger = options.logger ? console

  if logger.disableColor
    chalk.enabled = false

  testFailed = false

  error = (line, info) ->
    testFailed = true
    prefix = ""

    if info?.summary?
      logger.log chalk.red info.summary

    if line.location?
      l = line.location
      if l.start?
        prefix = "#{l.source}(#{l.start?.line},#{l.start?.column}): "
      else if l.first_line?
        prefix = "#{line.filename}(#{l.first_line+1},#{l.first_column}): "
        line = line.message
      logger.log chalk.red prefix + line
    else if line.name?
      stack = line.stack.split('\n')
      if stack[1].indexOf('Skill.runTests') >= 0
        logger.log chalk.red "Error executing inline code. #{stack[0]}"
      else
        logger.log chalk.red stack.join '\n'
    else if line.stack?
      logger.log chalk.red "[unknown location]"
      logger.log chalk.red line.stack.split('\n').join('\n')
    else
      logger.log chalk.red "[unknown location]"
      logger.log chalk.red line

  important = (line) ->
    logger.log chalk.inverse line

  doTest = ->
    filterReport = "no filter"
    if options?.filter
      filterReport = "filter: #{options.filter}"
    important "#{(new Date).toLocaleString()} running tests in #{options.root} with #{filterReport}"

    try
      skill = await require('./skill-builder').build(options.root)
    catch err
      return error err

    skill.projectInfo.testRoot = path.join skill.projectInfo.root, '.test'
    mkdirp.sync skill.projectInfo.testRoot
    testRoot = skill.projectInfo.testRoot

    fs.writeFileSync path.join(skill.projectInfo.testRoot,'project-config.json'), JSON.stringify(skill.projectInfo, null, 2), 'utf8'

    try
      lambda = skill.toLambda()
      fs.writeFileSync path.join(testRoot,'lambda.js'), lambda, 'utf8'
    catch err
      return error err

    testOptions =
      focusedFiles: (options.filter ? '').split(',')
      strictMode: !!options.strict
      region: options.region ? "en-US"
      testDevice: options.device ? 'show'
      reportProgress: (str) ->
        process.stdout.write str + "\n"

    try
      model = skill.toModelV2 testOptions.region
      fs.writeFileSync path.join(testRoot, 'model.json'), JSON.stringify(model, null, 2), 'utf8'
    catch err
      return error err


    await new Promise (resolve, reject) ->
      try
        skill.runTests testOptions, (err, result) ->
          logger.log ' '
          fs.writeFileSync path.join(testRoot,'libraryCode.js'), skill.libraryCode, 'utf8'
          if err?
            error err, result
            return resolve()

          fs.writeFileSync path.join(testRoot,'output.json'), JSON.stringify(result, null, 2), 'utf8'
          if result?.log?
            result.log.unshift (new Date).toLocaleString()
            fs.writeFileSync path.join(testRoot,'output.log'), result.log.join('\n'), 'utf8'
            for line in result.log
              if line.indexOf('✘') >= 0
                for s in line.split '\n'
                  if s.indexOf('✘') >= 0
                    logger.log chalk.red s
                  else
                    logger.log s
              else
                logger.log line

          if result.summary?[0] == '✔'
            important result.summary
          else
            testFailed = true
            if result.summary
              logger.log chalk.inverse.red result.summary
            else
              logger.log chalk.inverse.red 'failed to invoke skill'

          resolve()

      catch err
        error err
        resolve()

  if options.watch
    debounce = null
    scheduleTest = ->
      return if debounce?
      ping = ->
        debounce = null
        await doTest()
      debounce = setTimeout ping, 100

    config = await require('./project-config').loadConfig(options.root)

    chokidar.watch "#{config.root}/**/*.{litexa,coffee,js,json}", {
      ignored: [ path.join(config.root, 'node_modules') ]
      ignoreInitial: true
    }
    .on 'add', (path) ->
      console.log path
      scheduleTest()
    .on 'change', (path) ->
      scheduleTest()

    scheduleTest()

  else
    await doTest()
    unless options.dontExit
      if testFailed
        process.exit -1
      else
        process.exit 0

  return null
