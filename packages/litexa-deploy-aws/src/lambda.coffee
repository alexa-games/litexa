###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
rimraf = require 'rimraf'
util = require 'util'
crypto = require 'crypto'
AWS = require 'aws-sdk'
uuid = require 'uuid'
debug = require('debug')('litexa-deploy-lambda')

writeFilePromise = util.promisify fs.writeFile
readFilePromise = util.promisify fs.readFile

SupportedOS =
  LINUX: 'linux',
  OSX: 'darwin',
  WIN: 'win32'

writeFileIfDifferent = (filename, contents) ->
  readFilePromise filename, 'utf8'
  .catch (err) ->
    # fine if we can't read it, we'll assume we have to write
    return Promise.resolve()
  .then (fileContents) ->
    if contents == fileContents
      return Promise.resolve(false)
    else
      return writeFilePromise(filename, contents, 'utf8').then(-> Promise.resolve(true))


# TODO: Used for unit testing. Can remove when refactoring code to be more modular and test friendly
#   as eval does reduce runtime performance, but this should mainly be in the build process
exports.unitTestHelper = (funcName) ->
  args = Array.prototype.slice.call arguments
  eval funcName
  .apply this, args[1..]


exports.deploy = (context, logger) ->
  logger.log "deploying lambda"

  context.lambdaDeployStart = new Date
  lambdaContext =
    codeRoot: path.join context.deployRoot, 'lambda'
    litexaRoot: path.join context.projectRoot, 'litexa'

  call = (func) ->
    func context, logger, lambdaContext

  call preamble
  .then ->
    # all of this can happen at the same time
    step1 = [
      call writeReadme
      call writeSkillJS
      call copyNodeModules
      call ensureDynamoTable
    ]

    Promise.all(step1)
  .then ->
    call packZipFile
  .then ->
    call createZipSHA256
  .then ->
    call getLambdaConfig
  .then ->
    call updateLambdaConfig
    .then ->
      call updateLambdaCode
  .catch (err) ->
    if err.code != 'ResourceNotFoundException'
      throw err
    # doesn't exist, make it
    call createLambda
  .then ->
    call checkLambdaQualifier
  .then ->
    call checkLambdaPermissions
  .then ->
    call changeCloudwatchRetentionPolicy
  .then ->
    call checkForAssetsRoot
  .then ->
    call endLambdaDeployment
  .catch (err) ->
    logger.error "lambda deployment failed"
    throw err


preamble = (context, logger, lambdaContext) ->
  new Promise (resolve, reject) ->
    try
      require('./aws-config').handle(context, logger, AWS)

      mkdirp.sync lambdaContext.codeRoot

      lambdaContext.lambda = new AWS.Lambda

      context.lambdaName = [
        context.projectInfo.name
        context.projectInfo.variant
        "litexa"
        "handler"
      ].join('_')

      # the alias we're going to deploy to
      lambdaContext.qualifier = "release-" + context.artifacts.currentVersion

    catch err
      return reject(err)

    resolve()


writeReadme = (context, logger, lambdaContext) ->
  # readme
  readme = """
    This lambda was generated by the litexa package
    and uploaded using the @litexa/deploy-aws package
  """

  filename = path.join(lambdaContext.codeRoot,'readme.md')
  writeFileIfDifferent filename, readme
  .then (wrote) ->
    if wrote
      logger.log "wrote readme"


writeSkillJS = (context, logger, lambdaContext) ->
  code = context.skill.toLambda()

  filename = path.join(lambdaContext.codeRoot,'index.js')
  writeFileIfDifferent filename, code
  .then (wrote) ->
    if wrote
      logger.log "wrote index.js"


copyNodeModules = (context, logger, lambdaContext) ->
  sourceDir = path.join context.skill.projectInfo.litexaRoot, 'node_modules'
  targetDir = path.join lambdaContext.codeRoot
  modulesCache = path.join context.deployRoot, "modules.cache"

  logger.log "considering node_modules"

  # check to see if any files appear to be modified since the last time
  # we did this
  msSinceLastCopy = context.localCache.millisecondsSince 'copiedNodeModules'
  needsCopy = (location) ->
    unless fs.existsSync modulesCache
      return true
    unless msSinceLastCopy?
      return true

    secondInMillis = 1000
    secondsSinceLastCopy = Math.ceil msSinceLastCopy / secondInMillis


    if process.platform == SupportedOS.WIN
      # WINCOMPAT - find the first thing that has changed since the last copy. Could use a faster
      #   algorithm to find the last modified file more quickly.
      fileList = fs.readdirSync(sourceDir)
        .map (v) ->
          return { name: v, time: fs.statSync(path.join sourceDir, v).mtime.getTime() }

      # Grabs the timestamp of the most recently modified file from folder
      reducer = (prev, curr) -> return if prev.time > curr.time then prev else curr
      lastModifiedTime = fileList.reduce reducer, 0
        .time

      return lastModifiedTime > ((new Date).getTime() - (secondsSinceLastCopy * secondInMillis))
    else
      { execSync } = require('child_process')
      result = execSync "find -L #{sourceDir} -type f -atime -#{secondsSinceLastCopy}s | head -n 1"
      return result.length > 0

  unless needsCopy sourceDir
    logger.log "node modules appear to be up to date"
    return Promise.resolve()

  packageJSONPath = path.join context.skill.projectInfo.litexaRoot, 'package.json'
  unless fs.existsSync packageJSONPath
    logger.log "no package.json found at #{packageJSONPath}, skipping node_modules"
    return Promise.resolve()

  nodeModulesPath = path.join context.skill.projectInfo.litexaRoot, 'node_modules'
  unless fs.existsSync nodeModulesPath
    throw new Error "no node_modules found at #{nodeModulesPath}, but we did
      see #{packageJSONPath}. Aborting for now. Did you perhaps miss running
      `npm install` from your litexa directory?"
    return Promise.resolve()

  new Promise (resolve, reject) ->
    startTime = new Date

    { exec } = require('child_process')

    execCmd = "rsync -crt --copy-links --delete --exclude '*.git' #{sourceDir} #{targetDir}"
    if process.platform == SupportedOS.WIN
      # WINCOMPAT - Windows uses robocopy in place of rsync to ensure files get replicated to destination
      execCmd = "robocopy  #{sourceDir} #{targetDir} /mir /copy:DAT /sl /xf \"*.git\" /r:3 /w:4"

    exec execCmd, (err, stdout, stderr) ->
      logger.log "rsync: \n" + stdout if stdout
      deltaTime = (new Date) - startTime
      fs.writeFileSync modulesCache, ''
      logger.log "synchronized node_modules in #{deltaTime}ms"
      if err?
        reject(err)
      else if stderr
        logger.log stderr
        reject(err)
      else
        context.localCache.saveTimestamp 'copiedNodeModules'
        resolve()


packZipFile = (context, logger, lambdaContext) ->
  new Promise (resolve, reject) ->
    logger.log "beginning zip archive"
    zipStart = new Date

    lambdaContext.zipFilename = path.join context.deployRoot, 'lambda.zip'

    lambdaSource = path.join(context.deployRoot,'lambda')
    debug "source directory: #{lambdaSource}"
    { exec } = require('child_process')

    zipFileCreationLogging = (err, stdout, stderr) ->
      logger.log "Platform: #{process.platform}"
      if process.platform == SupportedOS.WIN
        # WINCOMPAT - deletes old zip and creates new zip. There may be a faster way to zip on Windows
        zip = require 'adm-zip'

        zipper = new zip
        zipper.addLocalFolder lambdaSource
        zipper.writeZip lambdaContext.zipFilename

      zipLog = path.join context.deployRoot, 'zip.out.log'
      fs.writeFileSync zipLog, stdout
      zipLog = path.join context.deployRoot, 'zip.err.log'
      fs.writeFileSync zipLog, "" + err + stderr
      if err?
        logger.error err
        throw "failed to zip lambda"
      deltaTime = (new Date) - zipStart
      logger.log "zip archiving complete in #{deltaTime}ms"

      return resolve()

    if process.platform == SupportedOS.WIN
      # WINCOMPAT - using rimraf instead of rm -f for compatability
      rimraf '../data.zip', zipFileCreationLogging
    else
      exec "rm -f ../data.zip && zip -rX ../lambda.zip *",
        {
          cwd: lambdaSource
          maxBuffer: 1024 * 500
        },
        zipFileCreationLogging


createZipSHA256 = (context, logger, lambdaContext) ->
  new Promise (resolve, reject) ->
    shasum = crypto.createHash('sha256')
    fs.createReadStream lambdaContext.zipFilename
    .on "data", (chunk) ->
      shasum.update chunk
    .on "end", ->
      lambdaContext.zipSHA256 = shasum.digest('base64')
      logger.log "zip SHA: #{lambdaContext.zipSHA256}"
      resolve()
    .on "error", (err) ->
      reject err


getLambdaConfig = (context, logger, lambdaContext) ->
  if context.localCache.lessThanSince 'lambdaUpdated', 30
    # it's ok to skip this during iteration, so do it every half hour
    lambdaContext.deployedSHA256 = context.localCache.getHash 'lambdaSHA256'
    logger.log "skipping Lambda #{context.lambdaName} configuration check"
    return Promise.resolve()

  logger.log "fetching Lambda #{context.lambdaName} configuration"

  params =
    FunctionName: context.lambdaName

  lambdaContext.lambda.getFunctionConfiguration(params).promise()
  .then (data) ->
    logger.log "fetched Lambda configuration"
    lambdaContext.deployedSHA256 = data.CodeSha256
    lambdaContext.deployedLambdaConfig = data
    setLambdaARN context, lambdaContext, data.FunctionArn
    Promise.resolve data


setLambdaARN = (context, lambdaContext, newARN) ->
  aliasedARN = "#{newARN}:#{lambdaContext.qualifier}"
  lambdaContext.baseARN = newARN
  context.lambdaARN = aliasedARN
  context.artifacts.save 'lambdaARN', aliasedARN


makeLambdaConfiguration = (context, logger) ->
  require('./iam-roles').ensureLambdaIAMRole(context, logger)
  .then ->
    loggingLevel = if context.projectInfo.variant in ['alpha', 'beta', 'gamma']
      undefined
    else
      'terse'

    loggingLevel = 'terse'

    config =
      Description: "Litexa skill handler for project #{context.projectInfo.name}"
      Handler: "index.handler" # exports.handler in index.js
      MemorySize: 256 # megabytes, mainly because this also means dedicated CPU
      Role: context.lambdaIAMRoleARN
      Runtime: "nodejs8.10"
      Timeout: 10 # seconds
      Environment:
        Variables:
          variant: context.projectInfo.variant
          loggingLevel: loggingLevel
          dynamoTableName: context.dynamoTableName
          assetsRoot: context.artifacts.get 'assets-root'


    if context.deploymentOptions.lambdaConfiguration?
      # if this option is present, merge that object into the config, key by key
      mergeValue = ( target, key, value, stringify ) ->
        if key of target
          if typeof(target[key]) == 'object'
            # recurse into objects
            unless typeof(value) == 'object'
              throw "value of key #{key} was expected to be an object in lambdaConfiguration, but was instead #{JSON.stringify value}"
            for k, v of value
              # variable value must be strings, so switch here
              if k == 'Variables'
                stringify = true
              mergeValue target[key], k, v, stringify
            return

        if stringify
          target[key] = '' + value
        else
          target[key] = value

      for k, v of context.deploymentOptions.lambdaConfiguration
        mergeValue config, k, v, false

    debug "Lambda config: " + JSON.stringify config, null, 2

    return config


createLambda = (context, logger, lambdaContext) ->
  logger.log "creating Lambda function #{context.lambdaName}"

  params =
    Code:
      ZipFile: fs.readFileSync(lambdaContext.zipFilename)
    FunctionName: context.lambdaName
    Publish: true,
    VpcConfig: {}

  makeLambdaConfiguration(context, logger)
  .then (lambdaConfig) ->
    for k, v of lambdaConfig
      params[k] = v
    lambdaContext.lambda.createFunction(params).promise()
  .then (data) ->
    logger.verbose 'create-function', data
    logger.log "creating LIVE alias for Lambda function #{context.lambdaName}"
    lambdaContext.deployedSHA256 = data.CodeSha256
    setLambdaARN context, lambdaContext, data.FunctionArn

    # create the live alias, to support easy
    # console based rollbacks in emergencies
    params =
      FunctionName: context.lambdaName
      FunctionVersion: '$LATEST'
      Name: 'LIVE'
      Description: 'Current live version, used to refer to this lambda by the Alexa skill. In an emergency, you can point this to an older version of the code.'

    lambdaContext.lambda.createAlias(params).promise()


updateLambdaConfig = (context, logger, lambdaContext) ->
  needsUpdating = false
  matchObject = (a, b) ->
    unless b?
      return needsUpdating = true
    for k, v of a
      if typeof(v) == 'object'
        matchObject v, b[k]
      else
        if v? and b[k] != v
          logger.log "lambda configuration mismatch: #{k}:#{b[k]} should be #{v}"
          needsUpdating = true

  makeLambdaConfiguration context, logger
  .then (lambdaConfig) ->
    matchObject lambdaConfig, lambdaContext.deployedLambdaConfig

    unless needsUpdating
      return Promise.resolve()

    logger.log "patching Lambda configuration"

    params =
      FunctionName: context.lambdaName

    for k, v of lambdaConfig
      params[k] = v

    lambdaContext.lambda.updateFunctionConfiguration(params).promise()


updateLambdaCode = (context, logger, lambdaContext) ->
  # todo: with node_modules it's much easier to get bigger than
  # updateFunctionCode supports... will have to go through S3 then?

  if lambdaContext.deployedSHA256 == lambdaContext.zipSHA256
    logger.log "Lambda function #{context.lambdaName} code already up to date"
    return Promise.resolve()

  logger.log "updating code for Lambda function #{context.lambdaName}"

  params =
    FunctionName: context.lambdaName
    Publish: true
    ZipFile: fs.readFileSync(lambdaContext.zipFilename)

  lambdaContext.lambda.updateFunctionCode(params).promise()
  .then (data) ->
    context.localCache.storeHash 'lambdaSHA256', data.CodeSha256


checkLambdaQualifier = (context, logger, lambdaContext) ->
  params =
    FunctionName: context.lambdaName
    Name: lambdaContext.qualifier

  lambdaContext.lambda.getAlias(params).promise()
  .catch (err) ->
    if err.code == "ResourceNotFoundException"
      # not found is fine, we'll make it
      params =
        FunctionName: context.lambdaName
        Name: lambdaContext.qualifier
        Description: "Auto created by Litexa"
        FunctionVersion: "$LATEST"
      lambdaContext.lambda.createAlias(params).promise()
      .catch (err) ->
        logger.error err
        throw "Failed to create alias #{lambdaContext.qualifier}"
        throw new Error "Failed to create alias #{lambdaContext.qualifier}"
      .then (data) ->
        logger.verbose 'createAlias', data
        Promise.resolve(data)
    else
      logger.error err
      throw "Failed to fetch alias for lambda #{context.lambdaName}, #{lambdaContext.qualifier}"
      Promise.resolve()
  .then (data) ->
    # the development head should always be latest
    if data.FunctionVersion == '$LATEST'
      return Promise.resolve()

    params =
      RevisionId: data.RevisionId
      FunctionName: context.lambdaName
      Name: lambdaContext.qualifier
      Description: "Auto created by Litexa"
      FunctionVersion: "$LATEST"

    lambdaContext.lambda.updateAlias(params).promise()


checkLambdaPermissions = (context, logger, lambdaContext) ->
  if context.localCache.timestampExists "lambdaPermissionsChecked-#{lambdaContext.qualifier}"
    return Promise.resolve()

  addPolicy = (cache) ->
    logger.log "adding policies to Lambda #{context.lambdaName}"
    params =
      FunctionName: context.lambdaName
      Action: 'lambda:InvokeFunction'
      StatementId: 'lc-' + uuid.v4()
      Principal: 'alexa-appkit.amazon.com'
      Qualifier: lambdaContext.qualifier

    lambdaContext.lambda.addPermission(params).promise()
    .catch (err) ->
      logger.error "Failed to add permissions to lambda: #{err}"
    .then (data) ->
      logger.verbose "addPermission: #{JSON.stringify(data, null, 2)}"

  removePolicy = (statement) ->
    logger.log "removing policy #{statement.Sid} from lambda #{context.lambdaName}"
    params =
      FunctionName: context.lambdaName
      StatementId: statement.Sid
      Qualifier: lambdaContext.qualifier

    lambdaContext.lambda.removePermission(params).promise()
    .catch (err) ->
      logger.error err
      throw "failed to remove bad lambda permission"

  logger.log "pulling existing policies"

  params =
    FunctionName: context.lambdaName
    Qualifier: lambdaContext.qualifier

  lambdaContext.lambda.getPolicy(params).promise()
  .catch (err) ->
    # ResourceNotFoundException is fine, might not have a policy
    if err.code != "ResourceNotFoundException"
      logger.error err
      throw "Failed to fetch policies for lambda #{context.lambdaName}"
  .then (data) ->
    promises = []
    foundCorrectPolicy = false
    if data?
      logger.log "reconciling policies against existing data"
      # analyze the existing one
      policy = JSON.parse(data.Policy)
      for statement in policy.Statement
        # is this the ask statement?
        continue unless statement.Principal?.Service == "alexa-appkit.amazon.com"
        # still the right contents?
        lambdaARN = context.artifacts.get 'lambdaARN'
        if lambdaARN? and
            statement.Resource == lambdaARN and
            statement.Effect == 'Allow' and
            statement.Action == 'lambda:InvokeFunction'
          foundCorrectPolicy = true
        else
          promises.push removePolicy(statement)

    unless foundCorrectPolicy
      promises.push addPolicy()

    Promise.all(promises)
    .then ->
      context.localCache.saveTimestamp "lambdaPermissionsChecked-#{lambdaContext.qualifier}"


endLambdaDeployment = (context, logger, lambdaContext) ->
  deltaTime = (new Date) - context.lambdaDeployStart
  logger.log "lambda deployment complete in #{deltaTime}ms"
  context.localCache.saveTimestamp 'lambdaUpdated'


ensureDynamoTable = (context, logger, lambdaContext) ->
  context.dynamoTableName = [
    context.projectInfo.name
    context.projectInfo.variant
    "litexa_handler_state"
  ].join '_'

  # if its existence is already verified, no need to do so anymore
  if context.localCache.timestampExists 'ensuredDynamoTable'
    return Promise.resolve()

  dynamo = new AWS.DynamoDB {
    params:
      TableName: context.dynamoTableName
  }

  logger.log "fetching dynamoDB information"
  dynamo.describeTable({}).promise()
  .catch (err) ->
    if err.code != 'ResourceNotFoundException'
      logger.error err
      throw "failed to ensure dynamoDB table exists"

    logger.log "dynamoDB table not found, creating #{context.dynamoTableName}"
    params =
      AttributeDefinitions: [
        {
          AttributeName: "userId"
          AttributeType: "S"
        }
      ],
      KeySchema: [
        {
          AttributeName: "userId"
          KeyType: "HASH"
        }
      ]
      ProvisionedThroughput:
        ReadCapacityUnits: 10,
        WriteCapacityUnits: 10

    dynamo.createTable(params).promise()
    .then ->
      context.localCache.saveTimestamp 'createdDynamoTable'
      dynamo.describeTable({}).promise()
  .then (data) ->
    logger.log "verified dynamoDB table exists"
    context.dynamoTableARN = data.Table.TableArn
    context.artifacts.save 'dynamoDBARN', data.Table.TableArn
    context.localCache.saveTimestamp 'ensuredDynamoTable'


# only modify the retention policy if it's creating an new log group
changeCloudwatchRetentionPolicy = (context, logger, lambdaContext) ->
  if context.localCache.timestampExists 'ensuredCloudwatchLogGroup'
    return Promise.resolve()
  logGroupName = "/aws/lambda/#{context.lambdaName}"
  cloudwatch = new AWS.CloudWatchLogs()
  params = {
    logGroupNamePrefix: logGroupName
  }
  cloudwatch.describeLogGroups(params).promise()
  .then (data) ->
    logGroupExists = false
    for logGroup in data.logGroups
      if logGroup.logGroupName == logGroupName
        logGroupExists = true
        break

    if logGroupExists
      context.localCache.saveTimestamp 'ensuredCloudwatchLogGroup'
      return Promise.resolve()

    params = { logGroupName }
    cloudwatch.createLogGroup(params).promise()
    .then ->
      logger.log "Created Cloudwatch log group for lambda"
      params = {
        logGroupName: logGroupName
        retentionInDays: 30
      }
      context.localCache.saveTimestamp 'ensuredCloudwatchLogGroup'

      cloudwatch.putRetentionPolicy(params).promise()
      .then ->
        logger.log "Updated CloudWatch retention policy to 30 days"
        context.localCache.saveTimestamp 'appliedLogRetentionPolicy'
        return Promise.resolve()

checkForAssetsRoot = (context, logger, lambdaContext) ->
  unless context.artifacts.get 'assets-root'
    logger.warning 'WARNING: Assets root is not set in the deployed lambda environment configuration.'
