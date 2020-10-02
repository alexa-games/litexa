###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

{ ParserError, formatLocationStart } = (require './errors').lib

# exclude a set of references we know we don't want shadowed
# anywhere, or rather know we want to allow access to
protectedNames = ['context']

class Scope
  constructor: (@location, @name, @parent) ->
    @tempCounter = parent?.tempCounter ? 0
    @variables = {}

  newTemporary: (location) ->
    name = "_tmp#{@tempCounter}"
    @tempCounter += 1
    @variables[name] =
      origin: location
    return name

  get: (name) ->
    if name of @variables
      return @variables[name]
    if @parent?
      return @parent.get name
    return null

  checkAllocate: (location, name) ->
    if name in protectedNames
      throw new ParserError location, "cannot create a new variable
        named `#{name}` here, as it is a protected name that already
        exists. Please choose a different name."

    if name of @variables
      v = @variables[name]
      throw new ParserError location, "cannot create a new variable
        named `#{name}` here, as a previous one was already defined at
        #{formatLocationStart v.origin}"

    if @referenceTester?(name)
        throw new ParserError location, "cannot create a new variable
          named `#{name}` here, as the name already exists in your inline
          code."

    @parent?.checkAllocate location, name

  allocate: (location, name) ->
    @checkAllocate location, name
    @variables[name] =
      origin: location
    return true

  checkAccessParent: (location, name) ->
    unless @parent
      throw new ParserError location, "cannot access local variable `#{name}`
        as it hasn't been declared yet. Did you mean to create a new
        variable here with the `local` statement?"

    if name of @parent.variables
      @parent.variables[name].accesedByDescendant = true
      return true

    if @parent.referenceTester?(name)
      return true

    @parent.checkAccessParent location, name

  checkAccess: (location, name) ->
    if name in protectedNames
      return true

    if name of @variables
      return true

    if @referenceTester?(name)
      return true

    @checkAccessParent location, name

  hasDescendantAccess: ->
    for k, v of @variables
      if v.accesedByDescendant
        return true

    return false


class exports.VariableScopeManager
  constructor: (location, name) ->
    # default root scope
    @currentScope = new Scope location, name, null
    @scopes = [ @currentScope ]

  depth: -> @scopes.length

  pushScope: (location, name) ->
    # creates a new scope, new added variables will exist at this level
    # but names can be resolved all the way to the root
    scope = new Scope location, name, @currentScope
    @currentScope = scope
    @scopes.push scope

  popScope: ->
    # lowest scope is discarded, contents are expected to be
    # unreferenced from here on
    unless @scopes.length > 1
      throw new ParserError @scopes[0].location,  "cannot popScope on root scope"

    @scopes.pop()
    @currentScope = @scopes[@scopes.length-1]

  newTemporary: (location) ->
    return @currentScope.newTemporary location

  allocate: (location, name) ->
    @currentScope.allocate location, name

  checkAccess: (location, name) ->
    @currentScope.checkAccess location, name
