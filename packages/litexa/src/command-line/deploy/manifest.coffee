###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

fs = require 'fs'
path = require 'path'
util = require 'util'
child_process = require 'child_process'
assert = require 'assert'
smapi = require '../api/smapi'

{ JSONValidator } = require('../../parser/jsonValidator').lib


testObjectsEqual = (a, b) ->
  if Array.isArray a
    unless Array.isArray b
      throw "#{JSON.stringify a} NOT EQUAL TO #{JSON.stringify b}"

    unless a.length == b.length
      throw "#{JSON.stringify a} NOT EQUAL TO #{JSON.stringify b}"

    for v, i in a
      testObjectsEqual v, b[i]
    return

  if typeof(a) == 'object'
    unless typeof(b) == 'object'
      throw "#{JSON.stringify a} NOT EQUAL TO #{JSON.stringify b}"

    # check all B keys are present in A, as long as B key actually has a value
    for k, v of b
      continue unless v?
      unless k of a
        throw "#{JSON.stringify a} NOT EQUAL TO #{JSON.stringify b}"

    # check that all values in A are the same in B
    for k, v of a
      testObjectsEqual v, b[k]
    return

  unless a == b
    throw "#{JSON.stringify a} NOT EQUAL TO #{JSON.stringify b}"


logger = console
writeFilePromise = util.promisify fs.writeFile
exec = util.promisify child_process.exec

askProfile = null

module.exports =
  deploy: (context, overrideLogger) ->
    logger = overrideLogger

    askProfile = context.deploymentOptions?.askProfile

    manifestContext = {}

    logger.log "beginning manifest deployment"

    loadSkillInfo context, manifestContext
    .then ->
      getManifestFromSkillInfo context, manifestContext
    .then ->
      buildSkillManifest context, manifestContext
    .then ->
      createOrUpdateSkill context, manifestContext
    .then ->
      updateModel context, manifestContext
    .then ->
      enableSkill context, manifestContext
    .then ->
      logger.log "manifest deployment complete, #{logger.runningTime()}ms"
    .catch (err) ->
      if err?.code?
        logger.error "SMAPI error: #{err.code ? ''} #{err.message}"
      else
        if err.stack?
          logger.error err.stack
        else
          logger.error JSON.stringify err
      throw "failed manifest deployment"


loadSkillInfo = (context, manifestContext) ->
  logger.log "loading skill.json"
  infoFilename = path.join context.projectRoot, 'skill'

  try
    manifestContext.skillInfo = require infoFilename
  catch err
    if err.code == 'MODULE_NOT_FOUND'
      writeDefaultManifest(context, path.join context.projectRoot, 'skill.coffee')
      throw "skill.* was not found in project root #{context.projectRoot}, so a default has been
        generated in CoffeeScript. Please modify as appropriate and try deployment again."
    logger.error err
    throw "Failed to parse skill manifest #{infoFilename}"
  Promise.resolve()

getManifestFromSkillInfo = (context, manifestContext) ->
  logger.log "building skill manifest"
  unless 'manifest' of manifestContext.skillInfo
    throw "Didn't find a 'manifest' property in the skill.* file. Has it been corrupted?"

  deploymentTarget = context.projectInfo.variant

  # Let's check if a deployment target specific manifest is being exported in the form of:
  # { deploymentTargetName: { manifest: {...} } }
  for key of manifestContext.skillInfo
    if key == deploymentTarget
      manifestContext.fileManifest = manifestContext.skillInfo[deploymentTarget].manifest

  unless manifestContext.fileManifest?
    # If we didn't find a deployment-target-specific manifest, let's try to get the manifest
    # from the top level of the file export.
    manifestContext.fileManifest = manifestContext.skillInfo.manifest

  unless manifestContext.fileManifest?
    throw "skill* is neither exporting a top-level 'manifest' key, nor a 'manifest' nested below
      the current deployment target '#{deploymentTarget}' - please export a manifest for either and
      re-deploy."

  Promise.resolve()

buildSkillManifest = (context, manifestContext) ->
  lambdaArn = context.artifacts.get 'lambdaARN'
  unless lambdaArn
    throw "Missing lambda ARN during manifest deployment. Has the Lambda been deployed yet?"

  fileManifest = manifestContext.fileManifest
  # pull the skill file's manifest into our template merge manifest, which
  # will set any non-critical values that were missing in the file manifest
  mergeManifest =
    manifestVersion: "1.0"
    publishingInformation:
      isAvailableWorldwide: false,
      distributionCountries: [ 'US' ]
      distributionMode: 'PUBLIC'
      category: 'GAMES'
      testingInstructions: 'no instructions'
      gadgetSupport: undefined
    privacyAndCompliance:
      allowsPurchases: false
      usesPersonalInfo: false
      isChildDirected: false
      isExportCompliant: true
      containsAds: false
    apis:
      custom:
        endpoint:
          uri: lambdaArn
        regions:
          NA:
            endpoint:
              uri: lambdaArn
        interfaces: []
    #events: {}
    #permissions: {}

  unless 'publishingInformation' of fileManifest
    throw "skill.json is missing publishingInformation. Has it been corrupted?"

  interfaces = mergeManifest.apis.custom.interfaces

  for key of fileManifest
    switch key
      when 'publishingInformation'
        # copy over all sub keys of publishing information
        for k, v of mergeManifest.publishingInformation
          mergeManifest.publishingInformation[k] = fileManifest.publishingInformation[k] ? v

        unless 'locales' of fileManifest.publishingInformation
          throw "skill.json is missing locales in publishingInformation.
            Has it been corrupted?"

        # dig through specified locales. TODO: compare with code language support?
        mergeManifest.publishingInformation.locales = {}
        manifestContext.locales = []

        # check for icon files that were deployed via 'assets' directories
        deployedIconAssets = context.artifacts.get('deployedIconAssets') ? {}
        manifestContext.deployedIconAssetsMd5Sum = ''

        for locale, data of fileManifest.publishingInformation.locales
          # copy over kosher keys, ignore the rest
          whitelist = ['name', 'summary', 'description'
            'examplePhrases', 'keywords', 'smallIconUri',
            'largeIconUri']
          copy = {}
          for k in whitelist
            copy[k] = data[k]

          # check for language-specific skill icon files that were deployed via 'assets'
          localeIconAssets = deployedIconAssets[locale] ? deployedIconAssets[locale[0..1]]
          # fallback to default skill icon files, if no locale-specific icons found
          unless localeIconAssets?
            localeIconAssets = deployedIconAssets.default

          # Unless user specified their own icon URIs, use the deployed asset icons.
          # If neither a URI is specified nor an asset icon is deployed, throw an error.
          if copy.smallIconUri?
            copy.smallIconUri = copy.smallIconUri
          else
            smallIconFileName = 'icon-108.png'
            if localeIconAssets? and localeIconAssets[smallIconFileName]?
              smallIcon = localeIconAssets[smallIconFileName]
              manifestContext.deployedIconAssetsMd5Sum += smallIcon.md5
              copy.smallIconUri = smallIcon.url
            else
              throw "Required smallIconUri not found for locale #{locale}. Please specify a
                'smallIconUri' in the skill manifest, or deploy an '#{smallIconFileName}' image via
                assets."

          if copy.largeIconUri?
            copy.largeIconUri = copy.largeIconUri
          else
            largeIconFileName = 'icon-512.png'
            if localeIconAssets? and localeIconAssets[largeIconFileName]?
              largeIcon = localeIconAssets[largeIconFileName]
              manifestContext.deployedIconAssetsMd5Sum += largeIcon.md5
              copy.largeIconUri = largeIcon.url
            else
              throw "Required largeIconUri not found for locale #{locale}. Please specify a
                'smallIconUri' in the skill manifest, or deploy an '#{largeIconFileName}' image via
                assets."

          mergeManifest.publishingInformation.locales[locale] = copy

          invocationName = context.deploymentOptions.invocation?[locale] ? data.invocation ? data.name
          invocationName = invocationName.replace /[^a-zA-Z0-9 ]/g, ' '
          invocationName = invocationName.toLowerCase()

          if context.deploymentOptions.invocationSuffix?
            invocationName += " #{context.deploymentOptions.invocationSuffix}"

          maxLength = 160
          if copy.summary.length > maxLength
            copy.summary = copy.summary[0..maxLength - 4] + '...'
            logger.log "uploaded summary length: #{copy.summary.length}"
            logger.warning "summary for locale #{locale} was too long, truncated it to #{maxLength}
              characters"

          unless copy.examplePhrases
            copy.examplePhrases = [
              "Alexa, launch <invocation>"
              "Alexa, open <invocation>"
              "Alexa, play <invocation>"
            ]

          copy.examplePhrases = for phrase in copy.examplePhrases
            phrase.replace /\<invocation\>/gi, invocationName

          # if 'production' isn't in the deployment target name, assume it's a development skill
          # and append a ' (target)' suffix to its name
          if (!context.projectInfo.variant.includes('production'))
            copy.name += " (#{context.projectInfo.variant})"

          manifestContext.locales.push {
            code: locale
            invocation: invocationName
          }

        unless manifestContext.locales.length > 0
          throw "No locales found in the skill.json manifest. Please add at least one."

      when 'privacyAndCompliance'
        # dig through these too
        for k, v of mergeManifest.privacyAndCompliance
          mergeManifest.privacyAndCompliance[k] = fileManifest.privacyAndCompliance[k] ? v

        if fileManifest.privacyAndCompliance.locales?
          mergeManifest.privacyAndCompliance.locales = {}
          for locale, data of fileManifest.privacyAndCompliance.locales
            mergeManifest.privacyAndCompliance.locales[locale] =
              privacyPolicyUrl: data.privacyPolicyUrl
              termsOfUseUrl: data.termsOfUseUrl

      when 'apis'
        # copy over any keys the user has specified, they might know some
        # advanced information that hasn't been described in a plugin yet,
        # trust the user on this
        if fileManifest.apis?.custom?.interfaces?
          for i in fileManifest.apis.custom.interfaces
            interfaces.push i

      else
        # no opinion on any remaining keys, so if they exist, copy them over
        mergeManifest[key] = fileManifest[key]

  # collect which APIs are actually in use and merge them
  requiredAPIs = {}
  context.skill.collectRequiredAPIs requiredAPIs
  for apiName of requiredAPIs
    found = false
    for i in interfaces
      if i.type == apiName
        found = true
    unless found
      logger.log "enabling interface #{apiName}"
      interfaces.push { type: apiName }

  # save it for later, wrap it one deeper for SMAPI
  manifestContext.manifest = mergeManifest
  finalManifest = { manifest: mergeManifest }

  # extensions can opt to validate the manifest, in case there are other
  # dependencies they want to assert
  for extensionName, extension of context.projectInfo.extensions
    validator = new JSONValidator finalManifest
    extension.compiler?.validators?.manifest { validator, skill: context.skill }
    if validator.errors.length > 0
      logger.error e for e in validator.errors
      throw "Errors encountered with the manifest, cannot continue."

  # now that we have the manifest, we can also validate the models
  for region of finalManifest.manifest.publishingInformation.locales
    model = context.skill.toModelV2(region)
    validator = new JSONValidator model
    for extensionName, extension of context.projectInfo.extensions
      extension.compiler?.validators?.model { validator, skill: context.skill }
      if validator.errors.length > 0
        logger.error e for e in validator.errors
        throw "Errors encountered with model in #{region} language, cannot continue"

  manifestContext.manifestFilename = path.join(context.deployRoot, 'skill.json')
  writeFilePromise manifestContext.manifestFilename, JSON.stringify(finalManifest, null, 2), 'utf8'


createOrUpdateSkill = (context, manifestContext) ->
  skillId = context.artifacts.get 'skillId'
  if skillId?
    manifestContext.skillId = skillId
    logger.log "skillId found in artifacts, getting information"
    updateSkill context, manifestContext
  else
    logger.log "no skillId found in artifacts, creating new skill"
    createSkill context, manifestContext


parseSkillInfo = (data) ->
  try
    data = JSON.parse data
  catch err
    logger.verbose data
    logger.error err
    throw "failed to parse JSON response from SMAPI"

  info = {
    status: data.manifest?.lastUpdateRequest?.status ? null
    errors: data.manifest?.lastUpdateRequest?.errors
    manifest: data.manifest
    raw: data
  }

  if info.errors
    info.errors = JSON.stringify(info.errors, null, 2)
    logger.verbose info.errors
  logger.verbose "skill is in #{info.status} state"

  return info


updateSkill = (context, manifestContext) ->
  smapi.call {
    askProfile
    command: 'get-skill'
    params: { 'skill-id': manifestContext.skillId }
    logChannel: logger
  }
  .catch (err) ->
    if err.code == 404
      Promise.reject "The skill ID stored in artifacts.json doesn't seem to exist in the deployment
        account. Have you deleted it manually in the dev console? If so, please delete it from the
        artifacts.json and try again."
    else
      Promise.reject err
  .then (data) ->
    needsUpdating = false
    info = parseSkillInfo data
    if info.status == 'FAILED'
      needsUpdating = true
    else
      try
        testObjectsEqual info.manifest, manifestContext.manifest
        logger.log "skill manifest up to date"
      catch err
        logger.verbose err
        logger.log "skill manifest mismatch"
        needsUpdating = true

    unless context.artifacts.get('skill-manifest-assets-md5') == manifestContext.deployedIconAssetsMd5Sum
      logger.log "skill icons changed since last update"
      needsUpdating = true

    unless needsUpdating
      logger.log "skill manifest up to date"
      return Promise.resolve()

    logger.log "updating skill manifest"
    smapi.call {
      askProfile
      command: 'update-skill'
      params: {
        'skill-id': manifestContext.skillId
        'file': manifestContext.manifestFilename
      }
      logChannel: logger
    }
    .then (data) ->
      waitForSuccess context, manifestContext.skillId, 'update-skill'
    .then ->
      context.artifacts.save 'skill-manifest-assets-md5', manifestContext.deployedIconAssetsMd5Sum
    .catch (err) ->
      Promise.reject err


waitForSuccess = (context, skillId, operation) ->
  return new Promise (resolve, reject) ->
    checkStatus = ->
      logger.log "waiting for skill status after #{operation}"
      smapi.call {
        askProfile
        command: 'get-skill-status'
        params: { 'skill-id': skillId }
        logChannel: logger
      }
      .then (data) ->
        info = parseSkillInfo data
        switch info.status
          when 'FAILED'
            logger.error info.errors
            return reject "skill in FAILED state"
          when 'SUCCEEDED'
            logger.log "#{operation} succeeded"
            context.artifacts.save 'skillId', skillId
            return resolve()
          when 'IN_PROGRESS'
            setTimeout checkStatus, 1000
          else
            logger.verbose data
            return reject "unknown skill state: #{info.status} while waiting on SMAPI"
        Promise.resolve()
      .catch (err) ->
        Promise.reject err
    checkStatus()


createSkill = (context, manifestContext) ->
  smapi.call {
    askProfile
    command: 'create-skill'
    params: { 'file': manifestContext.manifestFilename }
    logChannel: logger
  }
  .then (data) ->
    # dig out the skill id
    # logger.log data
    lines = data.split '\n'
    skillId = null
    for line in lines
      [k, v] = line.split ':'
      if k.toLowerCase().indexOf('skill id') == 0
        skillId = v.trim()
        break
    unless skillId?
      throw "failed to extract skill ID from ask cli response to create-skill"
    logger.log "in progress skill id #{skillId}"
    manifestContext.skillId = skillId
    waitForSuccess context, skillId, 'create-skill'
  .catch (err) ->
    Promise.reject err


writeDefaultManifest = (context, filename) ->
  logger.log "writing default skill.json"
  # try to make a nice looking name from the
  # what was the directory name
  name = context.projectInfo.name
  name = name.replace /[_\.\-]/gi, ' '
  name = name.replace /\s+/gi, ' '
  name = (name.split(' '))
  name = ( w[0].toUpperCase() + w[1...] for w in name )
  name = name.join ' '

  manifest = """
    ###
      This file exports an object that is a subset of the data
      specified for an Alexa skill manifest as defined at
      https://developer.amazon.com/docs/smapi/skill-manifest.html

      Please fill in fields as appropriate for this skill,
      including the name, descriptions, more regions, etc.

      At deployment time, this data will be augmented with
      generated information based on your skill code.
    ###

    module.exports =
      manifest:
        publishingInformation:
          isAvailableWorldwide: false,
          distributionCountries: [ 'US' ]
          distributionMode: 'PUBLIC'
          category: 'GAMES'
          testingInstructions: "replace with testing instructions"

          locales:
            "en-US":
              name: "#{name}"
              invocation: "#{name.toLowerCase()}"
              summary: "replace with brief description, no longer than 120 characters"
              description: "\""Longer description, goes to the skill store.
                Line breaks are supported."\""
              examplePhrases: [
                "Alexa, launch #{name}"
                "Alexa, open #{name}"
                "Alexa, play #{name}"
              ]
              keywords: [
                'game'
                'fun'
                'single player'
                'modify this list as appropriate'
              ]

        privacyAndCompliance:
          allowsPurchases: false
          usesPersonalInfo: false
          isChildDirected: false
          isExportCompliant: true
          containsAds: false

          locales:
            "en-US":
              privacyPolicyUrl: "https://www.example.com/privacy.html",
              termsOfUseUrl: "https://www.example.com/terms.html"
  """

  fs.writeFileSync filename, manifest, 'utf8'


waitForModelSuccess = (context, skillId, locale, operation) ->
  return new Promise (resolve, reject) ->
    checkStatus = ->
      logger.log "waiting for model #{locale} status after #{operation}"
      smapi.call {
        askProfile
        command: 'get-skill-status'
        params: { 'skill-id': skillId }
        logChannel: logger
      }
      .then (data) ->
        try
          info = JSON.parse data
          info = info.interactionModel[locale]
        catch err
          logger.verbose data
          logger.error err
          return reject "failed to parse SMAPI result"

        switch info.lastUpdateRequest?.status
          when 'FAILED'
            logger.error info.errors
            return reject "skill in FAILED state"
          when 'SUCCEEDED'
            logger.log "model #{operation} succeeded"
            context.artifacts.save "skill-model-etag-#{locale}", info.eTag
            return resolve()
          when 'IN_PROGRESS'
            setTimeout checkStatus, 1000
          else
            logger.verbose data
            return reject "unknown skill state: #{info.status} while waiting on SMAPI"
        Promise.resolve()
      .catch (err) ->
        reject(err)
    checkStatus()


updateModel = (context, manifestContext) ->
  promises = []
  for locale in manifestContext.locales
    promises.push updateModelForLocale context, manifestContext, locale
  Promise.all promises


updateModelForLocale = (context, manifestContext, localeInfo) ->
  locale = localeInfo.code

  modelDeployStart = new Date
  smapi.call {
    askProfile
    command: 'get-model'
    params: {
      'skill-id': manifestContext.skillId
      locale: locale
    }
    logChannel: logger
  }
  .catch (err) ->
    # it's fine if it doesn't exist yet, we'll upload
    unless err.code == 404
      Promise.reject err
    Promise.resolve "{}"
  .then (data) ->
    model = context.skill.toModelV2 locale

    # patch in the invocation from the skill manifest
    model.languageModel.invocationName = localeInfo.invocation

    # note, SMAPI needs an extra
    # interactionModel key around the model
    model =
      interactionModel:model

    filename = path.join context.deployRoot, "model-#{locale}.json"
    fs.writeFileSync filename, JSON.stringify(model, null, 2), 'utf8'

    needsUpdate = false
    try
      data = JSON.parse data
      # the version number is a lamport clock, will always mismatch
      delete data.version
      testObjectsEqual model, data
      logger.log "#{locale} model up to date"
    catch err
      logger.verbose err
      logger.log "#{locale} model mismatch"
      needsUpdate = true

    unless needsUpdate
      logger.log "#{locale} model is up to date"
      return Promise.resolve()

    logger.log "#{locale} model update beginning"
    smapi.call {
      askProfile
      command: 'update-model'
      params: {
        'skill-id': manifestContext.skillId
        locale: locale
        file: filename
      }
      logChannel: logger
    }
    .then ->
      waitForModelSuccess context, manifestContext.skillId, locale, 'update-model'
    .then ->
      dt = (new Date) - modelDeployStart
      logger.log "#{locale} model update complete, total time #{dt}ms"
    .catch (err) ->
      Promise.reject err

enableSkill = (context, manifestContext) ->
  logger.log "ensuring skill is enabled for testing"
  smapi.call {
    askProfile
    command: 'enable-skill'
    params: { 'skill-id': manifestContext.skillId }
    logChannel: logger
  }
  .catch (err) ->
    Promise.reject err

module.exports.testing =
  getManifestFromSkillInfo: getManifestFromSkillInfo