
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


path = require 'path'
fs = require 'fs'
md5File = require 'md5-file'
mime = require 'mime'

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

findAndRegisterFilesToUpload = ({ s3Context, languageInfo, logger }) ->
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
  sourceFilePath = path.join(fileDir, fileName)
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
  }

  # If we're deploying icon asset files, track them so we can use them
  # in case the user doesn't specify their own icon URIs in the manifest.
  iconFileNames = [ 'icon-108.png', 'icon-512.png' ]
  if iconFileNames.includes(fileName)
    s3Context.deployedIconAssets[language] = s3Context.deployedIconAssets[language] ? {}
    s3Context.deployedIconAssets[language][fileName] = {
      url: "#{s3Context.RESTRoot}/#{s3Key}"
      md5: md5
    }

listBucketAndUploadAssets = ({ s3Context, skillContext, logger, startToken }) ->
  # start by listing all the object in the bucket
  # so we get their MD5 hashes, note we might have to
  # page, so this function is recursive
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
    # now we can compare each file to upload against
    # the existing ones and avoid spending time on
    # redundant uploads
    for obj in data.Contents
      continue unless obj.Key of s3Context.assets
      info = s3Context.assets[obj.Key]
      info.s3MD5 = JSON.parse obj.ETag
      info.needsUpload = info.s3MD5 != info.md5

    # if we've paged, then also add the next page step
    if data.IsTruncated
      startToken = data.NextContinuationToken
      listBucketAndUploadAssets { s3Context, skillContext, logger, startToken }
    else
      uploadAssets { s3Context, skillContext, logger }


uploadAssets = ({ s3Context, skillContext, logger }) ->
  # collect the final work list
  s3Context.uploads = []

  for key, info of s3Context.assets
    if info.needsUpload
      info.key = key
      s3Context.uploads.push info
    else
      logger.verbose "skipping #{info.name} [#{info.md5Brief}]"

  logger.log "#{s3Context.uploads.length} assets need uploading"
  uploadBatch { s3Context, skillContext, logger }


uploadBatch = ({ s3Context, skillContext, logger }) ->
  # upload in batches to limit connection, open
  # file handles, and get a better idea of progress
  # this function recurses until we're done
  if s3Context.uploads.length == 0
    return endUploadAssets { s3Context, skillContext, logger }

  uploadPromises = []

  maxUploads = 5
  for i in [0...maxUploads]
    break if s3Context.uploads.length == 0
    job = s3Context.uploads.shift()

    params = {
      Key: job.key
      Body: fs.createReadStream job.sourceFilename
      ACL: "public-read"
      ContentType: mime.getType job.sourceFilename
    }

    logger.log "uploading #{job.name} -> #{job.key} [#{job.md5Brief}]"
    uploadPromises.push skillContext.S3.upload(params).promise()

  logger.log "#{s3Context.uploads.length} assets remaining in queue"
  startTime = new Date
  Promise.all(uploadPromises).then ->
    logger.log "segment uploaded in #{(new Date) - startTime}ms"
    uploadBatch { s3Context, skillContext, logger }


endUploadAssets = ({ s3Context, skillContext, logger }) ->
  deltaTime = (new Date()) - skillContext.assetDeploymentStart
  logger.log "asset deployment complete in #{deltaTime}ms"
  Promise.resolve()


module.exports = {
  collectUploadInfo
  listBucketAndUploadAssets
  prepareBucket
  validateS3BucketName
  validateS3PathName
}
