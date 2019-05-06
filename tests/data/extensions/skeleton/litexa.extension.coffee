
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


# This file documents the extension module format

# An extension module should export this single function, returning
# an object with some or all of the given keys below.
# The options argument is the value of the key with the same name
# as this module, in the user project's litexa.config.js/ts/json/coffee
# project configuration file.
# The lib argument is the same lib object passed down to the
# parser, and contains most of the objects used to construct
# a Litexa skill, including those added by other extensions.

module.exports = (options, lib) ->
  return
    # new language features, modifying the compiler
    language: languageStuff

    # adding new features to the compilation process
    compiler: compilerStuff

    # new asset pipeline features, supporting more asset types
    assetPipeline: assetPipelineStuff

    # runtime features, adding code to the handler directly
    runtime: runtimeStuff


# The language key in the exports defines additions to the parser
# and resulting skill object tree.
languageStuff =
  # an entry point to add new general runtime statements to
  # the Litexa language
  statements:

    # the key here is the top level rule name to insert into
    # the list of statements, and the value is the pegjs code
    # necessary to recognize the new statement, which can
    # include further supporting fragments
    "DoCoolThings": """
      DoCoolThings
        = 'Do' ___ a:Adjectives ___ 'things' {
          // can refer to anything in the lib object here
          pushCode( location(), new lib.DoThing(a) );
        }

      Adjectives
        = 'cool' / 'good' / 'great'
    """


  # an entry point to add test statements. Works the same
  # way as the statements key
  testStatements: {}

  # values to merge to the code library namespace made
  # visible to the compiler code in litexa.pegjs
  lib:
    # required earlier, or defined in this file
    MyStatementClass: MyStatementClass

    # no reason to require elsewhere if it's just used here
    MyExternalClass: require('./src/MyExternalClass.js')

    # note, the contents of lib are dynamic, so if you want
    # to derive from a class used there, you should do so
    # inside a function closure that customizes your class
    MyDerivedExternal: require('./src/MyDerivedExternal.js')(lib)

  # simple support for new tags
  sayTags:
    MyTag: (part) ->
      # this would add support for <MyTag something>
      # see implementation in say.coffee for how the part works

compilerStuff =
  # functions that take a JSON object and decide if it i s
  # suitably formed and conforms to any internal restrictions.
  validators:
    manifest: (record, manifest) ->
    model: (record, model) ->
    response: (record, response) ->
    directives:
      directiveName: (record, directive) ->
      otherDirective: (record, directive) ->

  # this list adds names to the compiler, allowing 'when'
  # statements to accept these without complaint. Note, you
  # do NOT have to list names you intend to handle but not
  # expose to authors, e.g. CONNECTION.Response
  validIntentNames: [
    'NAMESPACE.OtherIntent'
  ]


validatorFunction = (thing) ->

  unless thing.neededKey?
    record.missing 'neededKey'

  unless thing.stuff.required?
    record.missing 'stuff.required'

  record.requirePath thing, ['stuff', 'must', 'exist']

  unless thing.stuff.flag < 10
    record.error 'stuff.flag', 'should not be over 10'

  if thing.stuff.a != 'foo' and thing.stuff.b == 'bar'
    record.error ['stuff.a', 'stuff.b'],
      "stuff.b cannot be 'bar' if stuff.a is anything but 'foo'"

  if thing.name.split(' ').length < 2
    record.warning 'name.length', 'two or more words recommended'

  record.errorCharacters thing.name, /[a-zA-Z0-9]/g,
    'should only contain a-z letters in either case, and or numbers'


runtimeStuff =

  # This is the name of a single object that will be instantiated
  # at each request by passing the request context to the function
  # created by either of the above mechanisms. This object will be
  # visible to the litexa userland scope, so from inline code and
  # from litexa.
  apiName: "MyAPIName"

  # An entry point to require at runtime, makes the assumption that
  # this package will need to be installed in the litexa directoty
  # and so will be present in the execution environment.
  # Suitable for bigger packages that rely on heavier dependencies
  # that don't want to be packed together into a single blob.
  # Note: the runtime only promises to have JavaScript available,
  # anything else is up to the module to support.
  require: "thisPackageName/entryPoint.js"

  # Alternatively, this code will be packed into a function closure
  # and inlined into the main handler.
  # Suitable for lighter weight chunks of code with no dependencies.
  source: "function(context){
    //javascript code implementation
    return { userFacing:{}, events: {} };
  }"


# Either of the runtime strategies are required to produce a
# function that at runtime will be invoked to produce an object
# The function will be called from inside the concurrency wrapper,
# after the request has been parsed, but before the statemachine
# begins execution.

# The context argument is the same context object you can expect to
# see from litexa, i.e. it contains parsed request info, the dynamic
# variable scope state, the database interface, etc.

RuntimeFeature = (context) ->
  # insert pre statemachine code here, e.g. cache invalidator,
  # mandatory prefetches, etc. Please make a best effort to keep
  # this function as light as possible, as it WILL be run for EVERY
  # request sent to the skill.

  # if you're going to store any permanent data in the database,
  # please add only a single key, named the same as your API, prefixed
  # with a single underscore.
  # Note: the database backing is a replicated by-reference object
  # store, so any changes you make to the object will automatically
  # be persisted at the end of the request handler
  # reminder: you can only store JSON compatible data here
  myData = context.db.read('_MyAPIName')
  unless myData?
    myData = {}
    context.db.write('_MyAPIName', myData)

  # unless you absolutely must add data to the context object, please
  # keep track of your own runtime data in this closure, for example:
  myData =
    someCache: null
    aStoredOption: ''
    aStateFlag: false
    anAccumulator: []
    etc: 'more stuff'

  # all of the following keys are optional
  interface =
    # this is the object that will be assigned to a userland
    # visible variable as named in the 'runtime' object above.
    userFacing:
      # anything you'd like visible to the user in litexa
      # at the symbol MyAPIName.myFunc()
      myFunc: ->
        myData.someCache = await loadTheCachedData()
        myData.aStateFlag = true

      # or even just some data at MyAPIName.myConstant
      myConstant: "A special string"


    # this is a set of event handlers that will be invoked automatically
    # outside of the statemachine in the main handler code, at
    # specific times.
    events:
      # this is invoked after the statemachine hits a terminal transition
      # but before the final response object is generated. This is the
      # last chance to influence the context before it is used for that.
      afterStateMachine: ->

      # this is invoked after the final JSON form of the response
      # has been created, and is the last chance to modify it before
      # it is sent back to the Alexa service
      beforeFinalResponse: (response) ->

    # a list of additional requests that should be routed to "when"
    # statements. This list is merged at runtime with the validIntentNames
    # above. Note: you don't have to repeat those names here, and you
    # don't need to list every request type you intend to handle as
    # user facing up there.

    # Optionally, a function that will run when that request
    # type is received, and can manipulate the state machine's context object
    # note, these functions accumulate, that is to say two extension are
    # allowed to respond to the same request. If you're intercepting a
    # generic message, please make sure you're responding just to your
    # use case, i.e. by analyzing further contents of the request.
    requests:
      'AMAZON.ThingIntent': null
      'NAMESPACE.OtherIntent': (request) ->
        # install something in $slotName
        context.slots.slotName = context.request.path.to.thing
      'CONNECTION.Response': (request) ->
        # check this really is your response
        return unless request.request.something == 'myThing'

  return interface
