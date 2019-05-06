
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


randomIndex = (count) ->
  Math.floor Math.random() * count

shuffleArray = (array) ->
  shuffled = ( a for a in array )
  for i in [0...shuffled.length]
    j = i + Math.floor(Math.random() * (shuffled.length - i))
    a = shuffled[i]
    b = shuffled[j]
    shuffled[i] = b
    shuffled[j] = a
  return shuffled

randomArrayItem = (array) ->
  array[randomIndex(array.length)]

diceRoll = (sides) ->
  # produce a number between 1 and sides, inclusive
  sides = sides ? 6
  1 + Math.floor( Math.random() * sides )

diceCheck = (number, sides) ->
  diceRoll(sides) <= number

escapeSpeech = (line) ->
  return "" unless line?
  return "" + line

deepClone = (thing) ->
  JSON.parse( JSON.stringify(thing) )

isActuallyANumber = (data) -> not isNaN(parseInt(data))

pickSayString = (context, key, count) ->
  sayData = context.db.read('__sayHistory') ? []
  history = sayData[key] ? []
  value = 0
  switch
    when count == 2
      # with two, we can only toggle anyway
      if history[0]?
        value = 1 - history[0]
      else
        value = randomIndex(2)
      history[0] = value

    when count < 5
      # until 4, the pattern below is a little
      # over constrained, producing a repeating
      # set rather than a random sequence,
      # so we only guarantee
      # no adjacent repetition instead
      value = randomIndex(count)
      if value == history[0]
        value = ( value + 1 ) % count
      history[0] = value

    else
      # otherwise, guarantee we'll see at least
      # half the remaining options before repeating
      # one, up to a capped history of 8, beyond which
      # it's likely too difficult to detect repetition.
      value = randomIndex(count)
      for i in [0...count]
        break unless value in history
        value = ( value + 1 ) % count
      history.unshift value
      cap = Math.min 8, count / 2
      history = history[0...cap]

  sayData[key] = history
  context.db.write '__sayHistory', sayData
  return value


exports.DataTablePrototype =
  pickRandomIndex: ->
    return randomIndex(@length)

  find: (key, value) ->
    idx = @keys[key]
    return null unless idx?
    for row in [0...length]
      if @[row][idx] == value
        return row
    return null


exports.Logging =
  log: ->
    console.log.apply( null, arguments )
  error: ->
    console.error.apply( null, arguments )


minutesBetween = (before, now) ->
  return 999999 unless before? and now?
  Math.floor( Math.abs(now - before) / (60 * 1000) )

hoursBetween = (before, now) ->
  return 999999 unless before? and now?
  Math.floor( Math.abs(now - before) / (60 * 60 * 1000) )

daysBetween = (before, now) ->
  return 999999 unless before? and now?
  now = (new Date(now)).setHours(0, 0, 0, 0)
  before = (new Date(before)).setHours(0, 0, 0, 0)
  Math.floor( Math.abs(now - before) / ( 24 * 60 * 60 * 1000 ) )


Math.clamp = (min, max, x) ->
  Math.min( Math.max( min, x ), max )

rgbFromHex = (hex) ->
  return [0,0,0] unless hex?.length?
  hex = hex[2..] if hex.indexOf('0x') == 0
  hex = hex[1..] if hex.indexOf('#') == 0
  return switch hex.length
    when 3
      read = (v) ->
        v = parseInt(v, 16)
        return v + 16 * v
      [ read(hex[0]), read(hex[1]), read(hex[2]) ]
    when 6
      [ parseInt(hex[0..1],16), parseInt(hex[2..3],16), parseInt(hex[4..5],16) ]
    else
      [0,0,0]

hexFromRGB = (rgb) ->
  r = Math.clamp( 0, 255, Math.floor(rgb[0]) ).toString(16)
  g = Math.clamp( 0, 255, Math.floor(rgb[1]) ).toString(16)
  b = Math.clamp( 0, 255, Math.floor(rgb[2]) ).toString(16)
  r = "0" + r if r.length < 2
  g = "0" + g if g.length < 2
  b = "0" + b if b.length < 2
  r + g + b

rgbFromHSL = (hsl) ->
  h = ( hsl[0] % 360 + 360 ) % 360
  s = Math.clamp( 0.0, 1.0, hsl[1] )
  l = Math.clamp( 0.0, 1.0, hsl[2] )
  h /= 60.0
  c = (1.0 - Math.abs(2.0 * l - 1.0)) * s
  x = c * (1.0 - Math.abs(h % 2.0 - 1.0))
  m = l - 0.5 * c
  c += m
  x += m
  m = Math.floor( m * 255 )
  c = Math.floor( c * 255 )
  x = Math.floor( x * 255 )
  switch Math.floor(h)
    when 0 then return [c,x,m]
    when 1 then return [x,c,m]
    when 2 then return [m,c,x]
    when 3 then return [m,x,c]
    when 4 then return [x,m,c]
    else        return [c,m,x]

brightenColor = (c, percent) ->
  isHex = false
  unless Array.isArray(c)
    c = rgbFromHex(c)
    isHex = true
  c = interpolateRGB c, [255,255,255], percent / 100.0
  if isHex
    return hexFromRGB(c)
  return c

interpolateRGB = (c1, c2, l) ->
  [r, g, b] = c1
  r += (c2[0] - r) * l
  g += (c2[1] - g) * l
  b += (c2[2] - b) * l
  [r.toFixed(0), g.toFixed(0), b.toFixed(0)]


reportValueMetric = ( metricType, value, unit ) ->
  params =
    MetricData: []
    Namespace: 'Litexa'

  params.MetricData.push {
    MetricName: metricType
    Dimensions: [
      {
        Name: 'project'
        Value: litexa.projectName
      }
    ],
    StorageResolution: 60
    Timestamp: new Date().toISOString()
    Unit: unit ? 'None'
    Value: value ? 1
  }
  #console.log "reporting metric #{JSON.stringify(params)}"

  return unless cloudWatch?
  cloudWatch.putMetricData params, (err, data) ->
    if err?
      console.error( "Cloudwatch metrics write fail #{err}" )

litexa.extensions =
  postProcessors: []
  extendedEvents: {}
  load: (location, name) ->
    # during testing, this might already be in the shared context, skip it if so
    if name of litexa.extensions
      #console.log ("skipping extension load, already loaded")
      return

    testing = if litexa.localTesting then "(test mode)" else ""
    #console.log "loading extension #{location}/#{name} #{testing}"
    fullPath = "#{litexa.modulesRoot}/#{location}/#{name}/litexa.extension"
    lib = litexa.extensions[name] = require fullPath

    if lib.loadPostProcessor?
      handler = lib.loadPostProcessor(litexa.localTesting)
      if handler?
        #console.log "installing post processor for extension #{name}"
        handler.extensionName = name
        litexa.extensions.postProcessors.push handler

    if lib.events?
      for k, v of lib.events(false)
        #console.log "registering extended event #{k}"
        litexa.extensions.extendedEvents[k] = v


  finishedLoading: ->
    # sort the postProcessors by their actions
    processors = litexa.extensions.postProcessors
    count = processors.length

    # identify dependencies
    for a in processors
      a.dependencies = []
      continue unless a.consumesTags?
      for tag in a.consumesTags
        for b in processors when b != a
          continue unless b.producesTags?
          if tag in b.producesTags
            a.dependencies.push b

    ready = ( a for a in processors when a.dependencies.length == 0 )
    processors = ( p for p in processors when p.dependencies.length > 0 )
    sorted = []
    for guard in [0...count]
      break if ready.length == 0
      node = ready.pop()
      for p in processors
        p.dependencies = ( pp for pp in p.dependencies when pp != node )
        if p.dependencies.length == 0
          ready.push p
      processors = ( p for p in processors when p.dependencies.length > 0 )
      sorted.push node

    unless sorted.length == count
      throw new Error "Failed to sort postprocessors by dependency"

    litexa.extensions.postProcessors = sorted


class DBTypeWrapper
  constructor: (@db, @language) ->
    @cache = {}

  read: (name) ->
    if name of @cache
      return @cache[name]
    dbType = __languages[@language].dbTypes[name]
    value = @db.read name

    if dbType?.prototype?
      # if this is a typed variable, and it appears
      # the type is a constructible, e.g. a Class
      if value?
        # patch the prototype if it exists
        Object.setPrototypeOf value, dbType.prototype
      else
        # or construct a new instance
        value = new dbType
        @db.write name, value

    else if dbType?.Prepare?
      # otherwise if it's typed and it provides a
      # wrapping Prepare function
      unless value?
        if dbType.Initialize?
          # optionally invoke an initialize
          value = dbType.Initialize()
        else
          # otherwise assume we start from an
          # empty object
          value = {}
        @db.write name, value
      # wrap the cached object, whatever it is
      # the function wants to return. Note it's
      # still the input value object that gets saved
      # to the database either way!
      value = dbType.Prepare(value)

    @cache[name] = value
    return value

  write: (name, value) ->
    # clear out the cache on any writes
    delete @cache[name]

    dbType = __languages[@language].dbTypes[name]
    if dbType?
      # for typed objects, we can only replace with
      # another object, OR clear out the object and
      # let initialization happen again on the next
      # read, whenever that happens
      if not value?
        @db.write name, null
      else if typeof(value) == 'object'
        @db.write name, value
      else
        throw new Error "@#{name} is a typed variable, you can only assign an object or null to it."
    else
      @db.write name, value

  finalize: (cb) ->
    @db.finalize cb

# Monetization
isEntitledIsp = (stateContext, referenceName) ->
  isp = await getIspByReferenceName(stateContext, referenceName)
  return false unless isp?
  return isp.entitled == "ENTITLED"

getIspByReferenceName = (stateContext, referenceName) ->
  if stateContext.monetization.fetchEntitlements
    await fetchEntitlements stateContext

  for p in stateContext.monetization.inSkillProducts
    if p.referenceName == referenceName
      return p
  return null

buildPurchaseDirective = (stateContext, referenceName) ->
  isp = await getIspByReferenceName stateContext, referenceName
  unless isp?
    # console.log "buildPurchaseDirective: In Skill Product \"#{referenceName}\" not found."
    return

  stateContext.directives.push {
      "type": "Connections.SendRequest"
      "name": "Buy"
      "payload": {
        "InSkillProduct": {
          "productId": isp.productId
        }
      }
      "token": "bearer " + stateContext.event.context.System.apiAccessToken
    }

fetchEntitlements = (stateContext, ignoreCache = false) ->
  if !stateContext.monetization.fetchEntitlements and !ignoreCache
    return Promise.resolve()

  new Promise (resolve, reject) ->
    try
      https = require('https')
    catch
      console.log "skipping fetchEntitlements, no https present"
      reject()

    apiEndpoint = "api.amazonalexa.com"
    apiPath = "/v1/users/~current/skills/~current/inSkillProducts"
    token = "bearer " + stateContext.event.context.System.apiAccessToken
    language = "en-US"

    options =
      host: apiEndpoint
      path: apiPath
      method: 'GET'
      headers:
        "Content-Type": 'application/json'
        "Accept-Language": language
        "Authorization": token

    req = https.get options, (res) =>
      res.setEncoding("utf8")

      if res.statusCode != 200
        reject()

      returnData = ""
      res.on 'data', (chunk) =>
        returnData += chunk

      res.on 'end', () =>
        stateContext.monetization.inSkillProducts = JSON.parse(returnData).inSkillProducts
        stateContext.monetization.fetchEntitlements = false
        # console.log("fetchEntitlements " + JSON.stringify(stateContext.monetization))
        stateContext.db.write "__monetization", stateContext.monetization
        resolve()

    req.on 'error', (e) ->
      console.log 'Error calling InSkillProducts API: ' + e
      reject(e)

getMonetizationResponse = (context) ->
  response = { isMonetizationResponse : false }
  if context?.event?.request?.name not in [ "Buy", "Cancel" ]
    return response

  response.name = context.event.request.name

  if not context.event.request.payload?.purchaseResult?
    return response

  if not context.event.request.payload.productId?
    return response

  response.isMonetizationResponse = true

  response.purchaseResult = context.event.request.payload.purchaseResult
  response.reference_name = getIspByProductId(context, context.event.request.payload.productId).referenceName

  response

getIspByProductId = (stateContext, productId) ->
  for p in stateContext.monetization.inSkillProducts
    if p.productId == productId
      return p
  return null

buildCancelPurchaseDirective = (stateContext, referenceName) =>
  isp = await getIspByReferenceName(stateContext, referenceName)
  unless isp?
    # console.log "buildCancelPurchaseDirective: In Skill Product \"#{referenceName}\" not found."
    return

  stateContext.directives.push {
      "type": "Connections.SendRequest"
      "name": "Cancel"
      "payload": {
        "InSkillProduct": {
          "productId": isp.productId
        }
      }
      "token": "bearer " + stateContext.event.context.System.apiAccessToken
    }
