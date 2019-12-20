###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

path = require 'path'
fs = require 'fs'
md5File = require 'md5-file'
mime = require 'mime'
{ hasKeys, matchesGlobPatterns } = require('../lib/utils')


validateS3BucketName = (bucketName) ->
  safeNameRegex = /(?=^.{3,63}$)(?!^(\d+\.)+\d+$)(^(([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])\.)*([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])$)/g
  unless bucketName.match safeNameRegex
    throw new Error "S3 bucket name '#{bucketName}' does not follow the rules for bucket naming in
      https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html.
      Please rename your bucket in the Litexa config to follow these guidelines and try again."

validateS3PathName = (str) ->
  unsafeCharacterRegex = /[^0-9a-zA-Z\_\-\.\/]/g
  if str.match unsafeCharacterRegex
    throw new Error "S3 upload failed, disallowed name: `#{str}`"

prepareBucket = ({ s3Context, skillContext, logger }) ->
  skillContext.S3.listBuckets({}).promise()
  .then (data) ->
    for bucket in data.Buckets
      if bucket.Name == s3Context.bucketName
        logger.log "found S3 bucket #{s3Context.bucketName}"
        return Promise.resolve()

    skillContext.S3.createBucket({}).promise()
    .then (info) ->
      logger.log "created S3 bucket #{s3Context.bucketName}"
      return Promise.resolve()

collectUploadInfo = ({ s3Context, skillContext, logger, md5Override }) ->
  md5File = md5Override ? md5File
  logger.log "scanning assets, preparing hashes"

  s3Context.assetCount = 0
  s3Context.deployedIconAssets = {}

  languageInfo = skillContext.skill.projectInfo.languages
  findAndRegisterFilesToUpload { s3Context, languageInfo, logger }

  if s3Context.deployedIconAssets?
    skillContext.artifacts.save 'deployedIconAssets', s3Context.deployedIconAssets

  # Clean up deprecated artifact key, to declutter old artifacts files.
  # @TODO: This can eventually be removed.
  skillContext.artifacts.delete 'required-assets'

  logger.log "scanned #{s3Context.assetCount} assets in project"

findAndRegisterFilesToUpload = ({ s3Context, languageInfo }) ->
  assetTypes = [ 'assets', 'convertedAssets']

  for language, languageSummary of languageInfo
    for assetKey in assetTypes
      assets = languageSummary[assetKey]
      return unless assets?

      for fileName in assets.files
        fileDir = assets.root
        registerFileForUpload { s3Context, fileDir, fileName, language }

      unless language == 'default'
        defaultAssets = languageInfo.default[assetKey]

        # If we find default assets that aren't overridden in this language,
        # upload duplicates of the default files to this language.
        for fileName in defaultAssets.files
          unless assets.files.includes(fileName)
            fileDir = defaultAssets.root
            registerFileForUpload { s3Context, fileDir, fileName, language }


registerFileForUpload = ({ s3Context, fileDir, fileName, language }) ->
  sourceFilePath = "#{fileDir}/#{fileName}"
  s3Context.assetCount += 1
  s3Key = "#{s3Context.baseLocation}/#{language}/#{fileName}"
  validateS3PathName(s3Key)
  md5 = md5File.sync(sourceFilePath)

  s3Context.assets[s3Key] = {
    name: fileName
    sourceFilename: sourceFilePath
    md5: md5
    md5Brief: md5.slice(md5.length - 8)
    needsUpload: true
    firstTimeUpload: true
  }

  # If we're deploying icon asset files, track them so we can use them if the user doesn't
  # specify their own icon URIs in the manifest.
  iconFileNames = [ 'icon-108.png', 'icon-512.png' ]
  if iconFileNames.includes(fileName)
    s3Context.deployedIconAssets[language] = s3Context.deployedIconAssets[language] ? {}
    s3Context.deployedIconAssets[language][fileName] = {
      url: "#{s3Context.RESTRoot}/#{s3Key}"
      md5: md5
    }

listBucketAndUploadAssets = ({ s3Context, skillContext, logger, startToken }) ->
  # Start by listing all the objects in the bucket so we get their MD5 hashes.
  # Note: Since we might have to page, this function is recursive.
  params = {
    Prefix: s3Context.baseLocation
    ContinuationToken: startToken ? undefined
    MaxKeys: 1000
  }

  rangeStart = s3Context.listPage * params.MaxKeys
  range = "[#{rangeStart}-#{rangeStart + params.MaxKeys}]"
  logger.log "fetching S3 object metadata #{range}"
  s3Context.listPage += 1

  skillContext.S3.listObjectsV2(params).promise()
  .then (data) ->
    # Now we can compare each file to upload against existing uploads, to avoid spending time on
    # redundant uploads.
    for obj in data.Contents
      continue unless obj.Key of s3Context.assets
      info = s3Context.assets[obj.Key]
      info.s3MD5 = JSON.parse obj.ETag
      info.needsUpload = info.s3MD5 != info.md5
      info.firstTimeUpload = false

    # If we've paged, then also add the next page step.
    if data.IsTruncated
      startToken = data.NextContinuationToken
      listBucketAndUploadAssets { s3Context, skillContext, logger, startToken }
    else
      uploadAssets { s3Context, skillContext, logger }


uploadAssets = ({ s3Context, skillContext, logger }) ->
  # collect the final work list
  s3Context.uploads = []
  s3Context.uploadIndex = 0

  for key, info of s3Context.assets
    if info.needsUpload
      info.key = key
      s3Context.uploads.push info
    else
      logger.verbose "skipping #{info.name} [#{info.md5Brief}]"

  logger.log "#{s3Context.uploads.length} assets need uploading"

  assetSets = createAssetSets { s3Context, skillContext }
  assetSetPromises = []

  for assetSet, assetSetIndex in assetSets
    logger.verbose "Uploading asset set #{assetSetIndex + 1} of #{assetSets.length}"
    assetSetPromises.push(uploadAssetSet({ assetSet, s3Context, skillContext, logger, fs, mime }))

  Promise.all(assetSetPromises).then ->
    endUploadAssets { s3Context, skillContext, logger }


createAssetSets = ({ s3Context, skillContext }) ->
  # If object properties are not defined, just put all uploadable assets into a single genreic set.
  if not skillContext.deploymentOptions.s3Configuration?.uploadParams \
  or skillContext.deploymentOptions.s3Configuration.uploadParams.length is 0
    return [{ params: undefined, assets: [...s3Context.uploads] }]

  assetSets = []
  assetsToUpload = [...s3Context.uploads]
  defaultParams = undefined

  for uploadParam in skillContext.deploymentOptions.s3Configuration.uploadParams

    # @TODO: A config check like this should likely be done near the beginning of the Litexa deployment process.
    if hasKeys(uploadParam.params, ['Key', 'Body', 'ContentType', 'ACL'])
      throw new Error "An upload params element in s3Configuration.uploadParams is using
        one or more reserved keys. The 'Key', 'Body', 'ContentType', and 'ACL' keys are
        all reserved by Litexa."

    if not uploadParam.filter or (uploadParam.filter and uploadParam.filter.includes '*')
      defaultParams = uploadParam.params
    else
      assetSet = { params: uploadParam.params, assets: [] }
      for asset, assetIndex in assetsToUpload by -1
        if matchesGlobPatterns(asset.name, uploadParam.filter)
          assetSet.assets.push assetsToUpload.splice(assetIndex, 1)[0]

      if assetSet.assets.length > 0
        # If the filter matched any assets, add the asset set.
        assetSets.push assetSet

  # Group any remaining assets in a final set, and use default object
  # properties, if non-file-specific ones were specified.
  if assetsToUpload.length > 0
    assetSets.push { params: defaultParams, assets: [...assetsToUpload] }

  return assetSets


uploadAssetSet = ({ assetSet, s3Context, skillContext, logger, fs, mime }) ->
  if not assetSet or assetSet.assets.length is 0
    return

  segmentPromises = []

  maxUploads = 5
  for i in [0...maxUploads]
    break if assetSet.assets.length is 0
    job = assetSet.assets.pop()

    params = Object.assign({
      Key: job.key
      Body: fs.createReadStream job.sourceFilename
      ContentType: mime.getType job.sourceFilename
      ACL: "public-read"
    }, assetSet.params)

    logger.log "uploading #{job.name} -> #{job.key} [#{job.md5Brief}]"
    segmentPromises.push skillContext.S3.upload(params).promise()
    s3Context.uploadIndex++

  logger.log "#{s3Context.uploads.length - s3Context.uploadIndex} assets remaining in queue"
  startTime = new Date
  Promise.all(segmentPromises).then ->
    logger.log "segment uploaded in #{(new Date) - startTime}ms"
    uploadAssetSet { assetSet, s3Context, skillContext, logger, fs, mime }


endUploadAssets = ({ s3Context, skillContext, logger }) ->
  deltaTime = (new Date()) - skillContext.assetDeploymentStart
  logger.log "asset deployment complete in #{deltaTime}ms"
  Promise.resolve()


module.exports = {
  createAssetSets
  collectUploadInfo
  listBucketAndUploadAssets
  prepareBucket
  uploadAssetSet
  validateS3BucketName
  validateS3PathName
}
