path = require 'path'
fs = require 'fs'
md5File = require 'md5-file'
mime = require 'mime'


checkName = (str) ->
  safeTester = /[^0-9a-zA-Z\_\-\.\/]/g
  if str.match safeTester
    throw "S3 upload failed, disallowed name: `#{str}`"

validateS3BucketName = (bucketName) ->
  safeTester = /(?=^.{3,63}$)(?!^(\d+\.)+\d+$)(^(([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])\.)*([a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])$)/g
  unless bucketName.match safeTester
    throw "S3 bucket name '#{bucketName}' does not follow the rules for bucket naming in
      https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html.
      Please rename your bucket in the litexa config to follow these guidelines and try again."

module.exports =
  deploy: (context, logger) ->
    logger.log "deploying assets"
    skill = context.skill

    s3context = null
    Promise.resolve()
    .then ->
      AWS = require 'aws-sdk'
      require('./aws-config')(context, logger, AWS)
      context.assetDeploymentStart = new Date

      unless context.deploymentOptions?.S3BucketName
        throw new Error "couldn't find `S3BucketName` in the '#{context.deploymentName}' deployment
          parameters from this project's config file. Please specify the bucket name you'd like to
          deploy to or create."

      validateS3BucketName(context.deploymentOptions.S3BucketName)

      projectInfo = skill.projectInfo
      s3context =
        baseLocation: projectInfo.name + "/" + projectInfo.variant
        assets: {}
        listPage: 0
        bucketName: context.deploymentOptions.S3BucketName

      checkName s3context.baseLocation

      context.S3 = new AWS.S3 {
        params:
          Bucket: s3context.bucketName
      }

      region = context.S3.config.region
      s3context.RESTRoot =  "https://s3.#{region}.amazonaws.com/#{s3context.bucketName}"
      context.artifacts.save 'assets-root', s3context.RESTRoot + '/' + s3context.baseLocation + '/'

      prepareBucket context, logger, s3context
    .then ->
      collectUploadInfo(context, logger, s3context)
    .then ->
      listBucket context, logger, s3context, null
    .catch (error) ->
      logger.error error
      throw "failed assets deployment"


prepareBucket = (context, logger, s3context) ->
  context.S3.listBuckets({}).promise()
  .then (data) ->
    for bucket in data.Buckets
      if bucket.Name == s3context.bucketName
        logger.log "found S3 bucket #{s3context.bucketName}"
        return Promise.resolve()

    context.S3.createBucket({}).promise()
    .then (info) ->
      logger.log "created S3 bucket #{s3context.bucketName}"
      return Promise.resolve()


collectUploadInfo = (context, logger, s3context) ->
  logger.log "scanning assets, preparing hashes"
  projectInfo = context.skill.projectInfo
  s3context.assetCount = 0

  requiredAssets = [ 'icon-108.png', 'icon-512.png' ]
  requiredAssetInfo = {}

  for language, languageInfo of projectInfo.languages
    languageLocation = s3context.baseLocation + "/" + language

    addGroup = (group) ->
      return unless group?
      for name in group.files
        s3context.assetCount += 1
        sourceFilename = path.join group.root, name
        key = languageLocation + '/' + name
        checkName key
        md5 = md5File.sync sourceFilename
        s3context.assets[key] =
          name: name
          sourceFilename: sourceFilename
          md5: md5
          md5Brief: md5[md5.length-8...]
          needsUpload: true

        # make note of some key assets
        for requiredName in requiredAssets
          if requiredName == name
            requiredAssetInfo[name] =
              url: "#{s3context.RESTRoot}/#{key}"
              md5: md5
            break

    addGroup languageInfo.assets
    addGroup languageInfo.convertedAssets

  for name in requiredAssets
    unless name of requiredAssetInfo
      throw "Missing required asset file #{name}"

  context.artifacts.save 'required-assets', requiredAssetInfo

  logger.log "scanned #{s3context.assetCount} assets in project"

  Promise.resolve()


listBucket = (context, logger, s3context, startToken) ->
  # start by listing all the object in the bucket
  # so we get their MD5 hashes, note we might have to
  # page, so this function is recursive

  params =
    Prefix: s3context.baseLocation
    ContinuationToken: startToken ? undefined
    MaxKeys: 1000

  rangeStart = s3context.listPage * params.MaxKeys
  range = "[#{rangeStart}-#{rangeStart + params.MaxKeys}]"
  logger.log "fetching S3 object metadata #{range}"
  s3context.listPage += 1

  context.S3.listObjectsV2(params).promise()
  .then (data) ->
    # now we can compare each file to upload against
    # the existing ones and avoid spending time on
    # redundant uploads

    for obj in data.Contents
      continue unless obj.Key of s3context.assets
      info = s3context.assets[obj.Key]
      info.s3MD5 = JSON.parse obj.ETag
      info.needsUpload = info.s3MD5 != info.md5

    # if we've paged, then also add the next page step
    if data.IsTruncated
      listBucket context, logger, s3context, data.NextContinuationToken
    else
      uploadAssets context, logger, s3context


uploadAssets = (context, logger, s3context) ->
  # collect the final work list
  s3context.uploads = []

  for key, info of s3context.assets
    if info.needsUpload
      info.key = key
      s3context.uploads.push info
    else
      logger.verbose "skipping #{info.name} [#{info.md5Brief}]"

  logger.log "#{s3context.uploads.length} assets need uploading"
  uploadBatch context, logger, s3context


uploadBatch = (context, logger, s3context) ->
  # upload in batches to limit connection, open
  # file handles, and get a better idea of progress
  # this function recurses until we're done

  if s3context.uploads.length == 0
    return endUploadAssets context, logger, s3context

  uploadPromises = []


  maxUploads = 5
  for i in [0...maxUploads]
    break if s3context.uploads.length == 0
    job = s3context.uploads.shift()

    params =
      Key: job.key
      Body: fs.createReadStream job.sourceFilename
      ACL: "public-read"
      ContentType: mime.getType job.sourceFilename

    logger.log "uploading #{job.name} -> #{job.key} [#{job.md5Brief}]"
    uploadPromises.push context.S3.upload(params).promise()

  logger.log "#{s3context.uploads.length} assets remaining in queue"
  startTime = new Date
  Promise.all(uploadPromises).then ->
    logger.log "segment uploaded in #{(new Date) - startTime}ms"
    uploadBatch context, logger, s3context

endUploadAssets = (context, logger, s3context) ->
  deltaTime = (new Date()) - context.assetDeploymentStart
  logger.log "asset deployment complete in #{deltaTime}ms"
  Promise.resolve()


module.exports.testing = { validateS3BucketName }
