
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


AWS = require 'aws-sdk'
logger = null
iam = null

ensureIAMRole = (context, roleInfo) ->
  iam = new AWS.IAM

  roleInfo.missingPolicies = []
  roleInfo.extraneousPolicies = []
  roleInfo.arn = null
  roleInfo.roleNeededCreation = false

  roleInfo.timestampName = "ensureIAMRole-#{roleInfo.name}"
  roleInfo.artifactName = "iamRole-#{roleInfo.name}"

  # rarely need to do this
  if context.localCache.lessThanSince roleInfo.timestampName, 240
    logger.log "skipping IAM role #{roleInfo.name}"
    return Promise.resolve(context.artifacts.get roleInfo.artifactName)

  logger.log "ensuring IAM role #{roleInfo.name}"

  getRoleStep(roleInfo)
  .catch (err) ->
    if err?.code != 'NoSuchEntity'
      throw err

    # no worries, create it first then
    createRoleStep(roleInfo).then ->
      getRoleStep(roleInfo)
  .then (data) ->
    roleInfo.arn = data.Role.Arn
    policy = decodeURIComponent data.Role?.AssumeRolePolicyDocument
    if policy != JSON.stringify(roleInfo.trust)
      # oh, trust policy not right? No worries, right it first
      updateAssumeRolePolicyStep(roleInfo).then ->
        getPoliciesStep(roleInfo)
    else
      getPoliciesStep(roleInfo)
  .then ->
    reconcilePoliciesStep(roleInfo)
  .then ->
    waitForRoleReadyStep(roleInfo)
  .then ->
    logger.log "IAM Role #{roleInfo.name} ready"
    context.artifacts.save roleInfo.artifactName, roleInfo.arn
    context.localCache.saveTimestamp roleInfo.timestampName
    Promise.resolve(roleInfo.arn)
  .catch (err) ->
    logger.error err
    throw "Failed to fetch info for IAM role #{roleInfo.name}"


getRoleStep = (roleInfo) ->
  params =
    RoleName: roleInfo.name
  iam.getRole(params).promise()


createRoleStep = (roleInfo) ->
  logger.log "creating IAM role #{roleInfo.name}"
  roleInfo.roleNeededCreation = true

  params =
    AssumeRolePolicyDocument: JSON.stringify(roleInfo.trust)
    RoleName: roleInfo.name
    Description: roleInfo.description
  iam.createRole(params).promise()


updateAssumeRolePolicyStep = (roleInfo) ->
  logger.log "updating IAM role #{roleInfo.name} assume role policy document"

  params =
    PolicyDocument: JSON.stringify(roleInfo.trust)
    RoleName: roleInfo.name
  iam.updateAssumeRolePolicy(params).promise()


getPoliciesStep = (roleInfo) ->
  logger.log "pulling attached policies for IAM role #{roleInfo.name}"

  params =
    RoleName: roleInfo.name

  iam.listAttachedRolePolicies(params).promise()
  .then (data) ->
    # enforce the required policies
    policyInList = (list, arn) ->
      return true for p in list when p.PolicyArn == arn
      return false

    for required in roleInfo.policies
      unless policyInList data.AttachedPolicies, required.PolicyArn
        roleInfo.missingPolicies.push required

    for policy in data.AttachedPolicies
      unless policyInList roleInfo.policies, policy.PolicyArn
        roleInfo.extraneousPolicies.push policy

    Promise.resolve()


reconcilePoliciesStep = (roleInfo) ->
  promises = []

  missingPolicies = roleInfo.missingPolicies
  extraneousPolicies = roleInfo.extraneousPolicies

  for policy in missingPolicies
    policy = missingPolicies.shift()
    logger.log "adding policy #{policy.PolicyName}"

    params =
      PolicyArn: policy.PolicyArn
      RoleName: roleInfo.name
    promises.push iam.attachRolePolicy(params).promise()

  for policy in extraneousPolicies
    policy = extraneousPolicies.shift()
    logger.log "removing policy #{policy.PolicyName}"

    params =
      PolicyArn: policy.PolicyArn
      RoleName: roleInfo.name
    promises.push iam.detachRolePolicy(params).promise()

  if promises.length > 0
    logger.log "reconciling IAM role policy differences"

  Promise.all(promises)


waitForRoleReadyStep = (roleInfo) ->
  unless roleInfo.roleNeededCreation
    return Promise.resolve()

  # using the arn immediately appears to fail, so
  # wait a bit, maybe accessing it successfully from
  # here means other services can see it?
  new Promise (resolve, reject) ->
    params =
      RoleName: roleInfo.name

    waitForReady = ->
      logger.log "waiting for IAM role to be ready"
      iam.getRole params, (err, data) ->
        if err?
          setTimeout waitForReady, 1000
        else
          resolve()

    setTimeout waitForReady, 10000


exports.ensureLambdaIAMRole = (context, overrideLogger) ->
  logger = overrideLogger
  context.lambdaIAMRoleName = "litexa_handler_lambda"

  roleInfo =
    name: context.lambdaIAMRoleName
    trust:
      Version: "2012-10-17"
      Statement: [
        {
          Effect: "Allow"
          Principal:
            Service: "lambda.amazonaws.com"
          Action: "sts:AssumeRole"
        }
      ]

    policies: [
      { PolicyName: 'AWSLambdaBasicExecutionRole', PolicyArn: 'arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole'}
      { PolicyName: 'AmazonDynamoDBFullAccess', PolicyArn: 'arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess' }
      { PolicyName: 'CloudWatchFullAccess', PolicyArn: 'arn:aws:iam::aws:policy/CloudWatchFullAccess' }
    ]

    description: 'A role for Litexa input handlers, generated by
    the package @litexa/deploy-aws'


  ensureIAMRole(context, roleInfo)
  .then (arn) ->
    context.lambdaIAMRoleARN = arn
    Promise.resolve()
