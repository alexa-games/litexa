fs = require('fs')
mkdirp = require 'mkdirp'
path = require('path')
rimraf = require 'rimraf'

loadArtifacts = require('../deployment/artifacts').loadArtifacts
skillBuilder = require('./skill-builder')
smapi = require('./api/smapi')
LoggingChannel = require './loggingChannel'

###
# Utility for running ISP-related Litexa CLI commands, which query @smapi via the ASK CLI.
# @function init ... needs to be called before issuing any ISP commands
# @param args ... object which should at minimum provide:
#   @param root  ... directory where to search for Litexa project
#   @param stage ... deployment stage to use
###
module.exports =

  init: (args) ->
    @logger = new LoggingChannel {
      logPrefix: 'isp'
      logStream: args.logger ? console
      enableVerbose: args.verbose
    }
    @artifacts = args.artifacts
    @root = args.root
    @skillId = args.skillId
    @deployment = args.deployment
    @stage = args.stage
    @smapi = args.smapi || smapi

    await @initializeSkillInfo()

  initializeSkillInfo: () ->
    unless @artifacts and @skillId
      # Build the skill so we can retrieve the skill ID.
      skill = await skillBuilder.build(@root, @deployment)
      skill.projectInfo.variant = @deployment

      context = {
        projectInfo: skill.projectInfo
        projectRoot: skill.projectInfo?.root
        deploymentName: @deployment
        deploymentOptions: skill.projectInfo.deployments[@deployment]
      }

      @askProfile = context.deploymentOptions?.askProfile
      @ispDir = path.join skill.projectInfo?.root, 'isp', @deployment

      await loadArtifacts { context, @logger }
      await smapi.prepare @logger
      @artifacts = context.artifacts
      @skillId = @artifacts.get 'skillId'

  pullAndStoreRemoteProducts: () ->
    @pullRemoteProductSummaries()
    .then (productSummaries) =>
      @storeProductDefinitions(productSummaries)
    .then =>
      @logger.log "done"

  pullRemoteProductSummaries: () ->
    @pullRemoteProductList()
    .then (result) ->
      result = JSON.parse result
      if smapi.version.major < 2
        return result
      else
        return result.inSkillProductSummaryList

  pullRemoteProductList: () ->
    return new Promise (resolve, reject) =>
      @logger.log "querying in-skill products using askProfile '#{@askProfile}' and skill ID
        '#{@skillId}' ..."

      if smapi.version.major < 2
        command = 'list-isp-for-skill'
      else
        command = 'get-isp-list-for-skill-id'

      @smapi.call {
        @askProfile
        command
        params: {
          'skill-id': @skillId
          'stage': @stage
        }
        logChannel: @logger
      }
      .then (productList) ->
        resolve(productList)
      .catch (err) =>
        unless err.code == 'ENOENT'
          @logger.error "calling 'list-isp-for-skill' failed with error: #{err.message}"
          reject(err)
        # ENOENT just meant there was no ISP data on the server -> ignore
        resolve([])

  resetRemoteProductEntitlements: () ->
    if @stage == 'live'
      @logger.error "unable to modify remote in-skill products in 'live' stage -> please use 'development'"
      return

    remoteProducts = await @pullRemoteProductSummaries()
    resetPromises = []

    for remoteProduct in remoteProducts
      if smapi.version.major < 2
        command = 'reset-isp-entitlement'
        params =
          'isp-id': remoteProduct.productId
      else
        command = 'reset-entitlement-for-product'
        params =
          'product-id': remoteProduct.productId
          'stage': 'development'

      resetPromises.push @smapi.call { @askProfile, command, params, logChannel: @logger }

    @logger.log "resetting in-skill product entitlements for skill ID '#{@skillId}' ..."

    Promise.all(resetPromises)
    .catch (err) =>
      @logger.error "failed to call reset-isp-entitlement with error: #{err.message}"
      Promise.reject(err)

  storeProductDefinitions: (products) ->
    return new Promise (resolve, reject) =>
      unless Array.isArray(products)
        err = new Error "@smapi didn't return an array for 'list-isp-for-skill'"
        reject(err)

      rimraf.sync @ispDir
      mkdirp.sync @ispDir

      @logger.log "storing in-skill product definitions in #{@ispDir} ..."

      artifactSummary = {}

      if products.length == 0
        @logger.log "No products found"

      for product in products
        fileName = "#{product.referenceName}.json"
        filePath = path.join @ispDir, fileName
        productDefinition = await @getProductDefinition(product)
        @logger.verbose "writing #{filePath} ..."
        fs.writeFileSync filePath, JSON.stringify(productDefinition, null, '\t')
        artifactSummary["#{product.referenceName}"] = { productId: product.productId }

      @artifacts.save 'monetization', artifactSummary
      resolve()

  getProductDefinition: (product) ->
    new Promise (resolve, reject) =>
      if smapi.version.major < 2
        command = 'get-isp'
        params =
          'isp-id': product.productId
          'stage': @stage
      else
        command = 'get-isp-definition'
        params =
          'product-id': product.productId
          'stage': @stage

      @smapi.call { @askProfile, command, params, logChannel: @logger }
      .then (productDefinition) ->
        resolve(JSON.parse productDefinition)
      .catch (err) =>
        @logger.error "failed to retrieve in-skill product definition for
          '#{product.referenceName}' with error: #{err.message}"
        reject(err)

  pushLocalProducts: () ->
    if @stage == 'live'
      @logger.error "unable to modify remote in-skill products in 'live' stage -> please use 'development'"
      return

    localProducts = await @readLocalProducts()
    remoteProducts = await @pullRemoteProductSummaries()

    artifactSummary = {}

    for product in localProducts
      if @listContainsProduct(remoteProducts, product)
        @logger.verbose "found in-skill product '#{product.referenceName}' on server,
          updating product ..."
        await @updateRemoteProduct(product, artifactSummary)
      else
        @logger.verbose "didn't find in-skill product '#{product.referenceName}' on server,
          creating product ..."
        await @createRemoteProduct(product, artifactSummary)

    for remoteProduct in remoteProducts
      unless @listContainsProduct(localProducts, remoteProduct)
        @logger.warning "found in-skill product '#{remoteProduct.referenceName}' on server, but not
          locally: deleting product ..."
        await @deleteRemoteProduct(remoteProduct)

    @artifacts.save 'monetization', artifactSummary

  readLocalProducts: () ->
    return new Promise (resolve, reject) =>
      unless fs.existsSync @ispDir
        @logger.log "no ISP directory found at #{@ispDir}, skipping monetization upload"
        resolve()

      @logger.log "reading ISP data from #{@ispDir} ..."

      localProducts = []
      artifactSummary = @artifacts.get 'monetization'

      try
        for file in fs.readdirSync(@ispDir) when fs.lstatSync(path.join(@ispDir, file)).isFile()
          product = {}
          product.filePath = path.join(@ispDir, file)
          product.data = JSON.parse fs.readFileSync(product.filePath, 'utf8')
          # upgrade from older version
          unless product.data.inSkillProductDefinition
            product.data = { inSkillProductDefinition: product.data }
            fs.writeFileSync(product.filePath, JSON.stringify(product.data,null,2) 'utf8')
          product.referenceName = product.data.inSkillProductDefinition.referenceName
          product.productId = artifactSummary["#{product.referenceName}"]?.productId
          localProducts.push product
      catch err
        reject(err)

      resolve(localProducts)

  listContainsProduct: (list, product) ->
    for listProduct in list
      if (listProduct.productId == product.productId)
        return true
    return false

  createRemoteProduct: (product, artifactSummary) ->
    return new Promise (resolve, reject) =>
      @logger.log "creating in-skill product '#{product.referenceName}' from #{product.filePath}
        ..."

      if smapi.version.major < 2
        command = 'create-isp'
        params = { file: product.filePath }
      else
        command = 'create-isp-for-vendor'
        params = { 'create-in-skill-product-request': "file:#{product.filePath}" }

      @smapi.call { @askProfile, command, params, logChannel: @logger }
      .then (data) =>
        if smapi.version.major < 2
          product.productId = data.substring(data.search("amzn1"), data.search(" based"))
        else
          data = JSON.parse data
          product.productId = data.productId
        artifactSummary["#{product.referenceName}"] = { productId: product.productId }
        @logger.verbose "successfully created product"
      .then () =>
        @associateProduct(product)
      .then ->
        resolve()
      .catch (err) =>
        @logger.error "creating in-skill product '#{product.referenceName}' failed with error:
          #{err.message}"
        reject(err)

  updateRemoteProduct: (product, artifactSummary) ->
    return new Promise (resolve, reject) =>
      monetization = @artifacts.get 'monetization'
      unless monetization["#{product.referenceName}"]?.productId?
        @logger.error "unable to find product ID for '#{product.referenceName}' in artifacts"
        reject()

      productId = monetization["#{product.referenceName}"]?.productId

      @logger.log "updating in-skill product '#{product.referenceName}' from #{product.filePath}..."

      if smapi.version.major < 2
        command = 'update-isp'
        params =
          'isp-id': productId
          file: product.filePath
          stage: @stage
      else
        command = 'update-isp-for-product'
        params =
          'product-id': productId
          'in-skill-product': "file:#{product.filePath}"
          stage: @stage

      @smapi.call { @askProfile, command, params, logChannel: @logger }
      .then (data) =>
        @logger.verbose "successfully updated product"
        artifactSummary["#{product.referenceName}"] = {
          productId: productId
        }
        resolve()
      .catch (err) =>
        @logger.error "updating in-skill product '#{product.referenceName}' failed with error:
          #{err.message}"
        reject(err)

  deleteRemoteProduct: (product) ->
    return new Promise (resolve, reject) =>
      @disassociateProduct(product)
      .then =>
        @logger.log "deleting in-skill product '#{product.referenceName}' from server ..."
        if smapi.version.major < 2
          command = 'delete-isp'
          params =
            'isp-id': product.productId
            stage: @stage
        else
          command = 'delete-isp-for-product'
          params =
            'product-id': product.productId
            stage: @stage

        @smapi.call { @askProfile, command, params, logChannel: @logger }
      .then (data) =>
        @logger.verbose "successfully deleted product"
        resolve()
      .catch (err) =>
        @logger.error "deleting in-skill product '#{product.referenceName}' failed with error:
          #{err.message}"
        reject(err)

  associateProduct: (product) ->
    return new Promise (resolve, reject) =>
      @logger.log "associating in-skill product '#{product.referenceName}' to skill ID '#{@skillId}' ..."

      if smapi.version.major < 2
        command = 'associate-isp'
        params =
          'isp-id': product.productId
          'skill-id': @skillId
      else
        command = 'associate-isp-with-skill'
        params =
          'product-id': product.productId
          'skill-id': @skillId

      @smapi.call { @askProfile, command, params, logChannel: @logger }
      .then (data) =>
        @logger.verbose "successfully associated product"
        resolve()
      .catch (err) =>
        @logger.error "associating in-skill product '#{product.referenceName}' failed with error:
          #{err.message}"
        reject(err)

  disassociateProduct: (product) ->
    return new Promise (resolve, reject) =>
      @logger.log "disassociating in-skill product '#{product.referenceName}' from skill '#{@skillId}' ..."

      if smapi.version.major < 2
        command = 'disassociate-isp'
        params =
          'isp-id': product.productId
          'skill-id': @skillId
      else
        command = 'disassociate-isp-with-skill'
        params =
          'product-id': product.productId
          'skill-id': @skillId

      @smapi.call { @askProfile, command, params, logChannel: @logger }
      .then (data) =>
        @logger.verbose "successfully disassociated product"
        resolve()
      .catch (err) =>
        @logger.error "disassociating in-skill product '#{product.referenceName}' failed with error:
          #{err.message}"
        reject(err)
