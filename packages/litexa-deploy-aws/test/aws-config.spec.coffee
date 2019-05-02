{assert, expect} = require('chai')
{match, spy, stub} = require('sinon')
{deploymentTargetConfiguration} = require('./helpers')

fs = require 'fs'
path = require 'path'
rimraf = require 'rimraf'
mkdirp = require 'mkdirp'
AwsConfig = require('../src/aws-config')
AWS = require 'aws-sdk'

describe 'Setting up AWS credentials from aws-config', ->
  loggerInterface = undefined
  context = undefined

  beforeEach ->
    loggerInterface = {
      log: () -> undefined
    }

    context =
      deploymentName: 'development'
      projectConfig:
        root: '.'
      deploymentOptions:
        awsProfile: 'testProfileThatDoesNotExist'
    fs.writeFileSync 'aws-config.json', JSON.stringify(deploymentTargetConfiguration, null, 2), 'utf8'
    mkdirp.sync('.deploy')

  afterEach ->
    rimraf.sync('.deploy')
    fs.unlinkSync 'aws-config.json'

  it 'throws an error if it cannot find the specified deployment target in aws-config.json', ->
    context.deploymentName = 'nonexistentTarget'
    callAwsConfig = -> AwsConfig(context)
    expect(callAwsConfig).to.throw("Failed to load aws-config.json: No AWS credentials exist
      for the `#{context.deploymentName}` deployment target. See @litexa/deploy-aws/readme.md for
      details on your aws-config.json.")

  it 'throws an error if there is no secretAccessKey in the target\'s aws config', ->
    fs.unlinkSync 'aws-config.json'
    logSpy = spy(loggerInterface, 'log')
    callAwsConfig = -> AwsConfig(context, loggerInterface, AWS)
    expect(callAwsConfig).to.throw(
      "Failed to load the AWS profile #{context.deploymentOptions.awsProfile}.")
    assert(logSpy.neverCalledWith(match("loaded AWS config from aws-config.json")),
      'indicated that it did not get credentials from aws-config.json')
    assert(logSpy.neverCalledWith(match("loaded AWS profile .*")),
      'indicates it never loaded the AWS profile')

    fs.writeFileSync 'aws-config.json', "restore as dummy file for cleanup", 'utf8'

  it 'sets AWS config from file', ->
    logSpy = spy(loggerInterface, 'log')
    assert(!context.AWSConfig?, 'context.AWSConfig does not exist before function call')
    assert(context.projectConfig?, 'project config exists in the input')
    assert(context.deploymentName?, 'deployment name exists in the input')
    assert(context.deploymentOptions?, 'deployment options in input exists')
    AwsConfig(context, loggerInterface, AWS)

    assert(context.AWSConfig?, 'context.AWSConfig was populated')
