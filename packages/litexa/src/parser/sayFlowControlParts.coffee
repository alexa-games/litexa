{ ParserError } = require('./errors.coffee').lib

lib = {}
module.exports = lib

class lib.PartListPart
  constructor: (@location, @parts) ->
    unless @parts?.length
      throw new ParserError @location, "No parts found in PartListPart (this should not happen, please contact a litexa dev!)"

  isPartListPart: true

  toString: -> @parts.join('')

  visit: (depth, fn) ->
    fn(depth, @)
    depth += 1
    part.visit(depth, fn) for part in @parts

  toRegex: -> ( p.toRegex() for p in @parts ).join ''
  toTestRegex: -> ( p.toTestRegex() for p in @parts ).join ''

  toLambda: (options) ->
    # when working across a list of parts, we need to
    # handle the automatic tag closing behaviors
    result = []
    tagContext = []
    closeTags = ->
      if tagContext.length == 0
        return ''
      closed = []
      for tag in tagContext by -1
        closed.push tag
      tagContext = []
      '"' + closed.join('') + '"'

    result = for p in @parts
      if p.open and p.tag
        tagContext.push "</#{p.tag}>"
      if p.proxy?.closeSSML?
        tagContext.push p.proxy.closeSSML()

      code = p.toLambda options

      if p.tagClosePos?
        closed = closeTags()
        if closed
          before = code[0...p.tagClosePos] + '"'
          after = '"' + code[p.tagClosePos..]
          code =  [before, closed, after].join '+'

      if p.needsEscaping
        "escapeSpeech( #{code} )"
      else
        code

    closed = closeTags()
    result.push closed if closed
    result.join(' + ')


  express: (context) -> ( p.express(context) for p in @parts ).join("")

  toUtterance: ->
    parts = ( p.toUtterance() for p in @parts )

    permute = (head, tail) ->
      return head unless tail?.length > 0
      all = []
      tails = permute tail[0], tail[1..]
      if typeof(tails) == 'string'
        tails = [ tails ]
      if Array.isArray head
        for i in head
          top = [i]
          for t in tails
            all.push top.concat t
      else
        top = [head]
        for t in tails
          all.push top.concat t
      return all

    flat = permute parts[0], parts[1..]

    for f, i in flat
      continue unless Array.isArray(f)
      complex = false
      for p in f
        complex = true if typeof(p) != 'string'
      unless complex
        flat[i] = f.join('')

    return flat


class lib.AlternatingPart
  constructor: (@location, @alternates) ->

  visit: (depth, fn) ->
    fn(depth, @)
    depth += 1
    for a in @alternates
      a.visit depth, fn

  isAlternatingPart: true

  toRegex: -> throw new ParserError @location, "Alternation is not supported yet in test strings"
  toTestRegex: -> @toRegex()

  toString: -> "#{@alternates[0]}"

  toLambda: (options) ->
    sayKey = require('./sayCounter').get()
    fragments = []
    for a in @alternates
      frag = a.toLambda(options)
      if a.needsEscaping
        frag = "escapeSpeech( #{frag} )"
      fragments.push frag

    "pickSayFragment(context, #{sayKey}, [#{fragments.join(', ')}])"

  express: (context) ->
    idx = Math.floor Math.random() * @alternates.length
    @alternates[idx].express(context)

  toUtterance: ->
    all = []
    for a in @alternates
      all = all.concat a.toUtterance()
    return all
