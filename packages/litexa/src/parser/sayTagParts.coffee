{ ParserError } = require('./errors.coffee').lib

lib = {}
module.exports = lib

class lib.TagPart
  constructor: (skill, @location, @code, @content, @variable) ->
    validFontSizes = [2, 3, 5, 7]
    @attributes = {}
    @open = false

    openUnlessContent = =>
      @open = true
      if @content?.trim().length > 0
        @open = false

    switch @code
      when "!"
        @tag = 'say-as'
        @attributes =
          'interpret-as': 'interjection'
      when "..."
        @tag = 'break'
        @attributes =
          time: @variable
      when "sfx"
        @tag = null
        @proxy = @content
        @content = null
      when "fontsize"
        unless parseInt(@variable) in validFontSizes
          throw new ParserError @location, "invalid font size #{@variable}, expecting one of #{JSON.stringify validFontSizes}"
        @tag = 'font'
        @attributes =
          size: @variable
        openUnlessContent()
      when "center"
        @tag = 'div'
        @attributes =
          align: 'center'
        openUnlessContent()
      when "i", "b", "u"
        @tag = @code
        openUnlessContent()
      else
        # look at extensions that might handle this
        extensions = skill.getExtensions()
        info = null
        if extensions?
          for name, ext of extensions
            info = ext?.language?.sayTags?[@code]
            break if info?
        unless info?
          throw new ParserError @location, "unknown tag <#{@code}>"
        info.process?(@)


  toString: ->
    switch @code
      when "!"
        return "<#{@code}#{@content}>"
      when "..."
        return "<#{@code}#{@variable}>"
      when "sfx"
        return "<#{@code} #{@proxy}>"
      else
        return "<#{@code}>"

  toUtterance: ->
    throw new ParserError null, "you cannot use a tag part in an utterance"
  toSSML: (language) ->
    unless language
      language = "default"
    if @tag?
      attributes = ( "#{k}='#{v}'" for k, v of @attributes )
      if @codeAttributes?
        for k, v of @codeAttributes
          attributes.push """#{k}='" + #{v} + "'"""
      attributes = attributes.join ' '
      if attributes.length > 0
        attributes = ' ' + attributes
      if @open
          "<#{@tag}#{attributes}>"
      else
        if @content
          "<#{@tag}#{attributes}>#{@content}</#{@tag}>"
        else
          "<#{@tag}#{attributes}/>"
    else if @proxy?
      @proxy.toSSML language
    else if @verbatim
      @verbatim
    else
      ""

  toLambda: (options) ->
    if @proxy?
      return @proxy.toSSMLFunction options.language
    '"' + @toSSML(options.language) + '"'

  express: (context) -> @toSSML(context.language)
  toRegex: ->
    str = @toSSML()
    # escape regex control characters
    str = str.replace( /\?/g, '\\?' )
    str = str.replace( /\./g, '\\.' )
    str = str.replace( /\//g, '\\/' )
    "(#{str})"
  toTestRegex: ->
    switch @code
      when "!"
        "(#{@toRegex()}|(<!#{@content}>))"
      when "..."
        "(#{@toRegex()}|(<...#{@attributes.time}>))"
      when "sfx"
        testSFXMatch = "#{if (@proxy?.name && @proxy?.type) then "|(<#{@proxy.name}.#{@proxy.type}>)|(<#{@proxy.name}>)" else ''}"
        "(#{@toRegex()}#{testSFXMatch})"
      else
        @toRegex()

  toTestScore: -> return 9
  toLocalization: ->
    return @toString()
