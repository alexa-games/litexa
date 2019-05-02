# a project collects more than one file that contributes to
# the same skill.

# Expected file types:
#  * .litexa is the state machine language
#  * .js / .coffee are code library files
#  * .csv are data files?

coffee = require 'coffeescript'
{ Skill } = require './skill.coffee'

exp = module.exports

fileCategories = [
  {
    name: 'build'
    regex: /([\w\.\-_\s]+\.build)\.([^\.]+)$/
  }
  {
    name: 'test'
    regex: /([\w\.\-_\s]+\.test)\.([^\.]+)$/
  }
  {
    name: 'regular'
    regex: /([\w\.\-_\s]+)\.([^\.]+)$/
  }
]

exp.infoFromFilename = (filename) ->
  test = (type, regex) ->
    match = regex.exec filename
    if match?
      return  {
        category: type
        name: match[1]
        extension: match[2]
      }
  for info in fileCategories
    res = test info.name, info.regex
    return res if res?
  return null


class exp.File
  constructor: (@name, language, @extension, content, @fileCategory) ->
    @raw = {}
    @content = {}
    @replaceContent(language, content)

  isFile: true
  replaceContent: (language, content) ->
    unless content?
      console.log language, content
      throw new Error "probably missing language at file replace content"
    @raw[language] = content
    @content[language] = content
    @dirty = true

  filename: -> "#{@name}.#{@extension}"

  contentForLanguage: (language) ->
    return @content[language] if language of @content
    any = v for k, v of @content
    return @content.default ? any

  rawForLanguage: (language) ->
    return @raw[language] if language of @raw
    return @raw.default


class exp.JavaScriptFile extends exp.File
  isCode: true


class exp.LiterateAlexaFile extends exp.File
  replaceContent: (language, content) ->
    # normalize line endings: CRLF to just LF
    content = content.replace /\r\n/g, '\n'

    # normalize line endings: just CR to just LF
    content = content.replace /\r/g, '\n'

    # add end of file signal for parser
    content += '\u001A'

    super language, content


class exp.CoffeeScriptFile extends exp.File
  constructor: (name, language, extension, source, fileCategory) ->
    super(name, language, extension, "", fileCategory)
    @content = {}
    @replaceContent 'default', source

  isCode: true

  replaceContent: (language, source) ->
    @dirty = true
    @content[language] = ""
    @raw[language] = source
    @exception = null
    try
      @content[language] = coffee.compile source, {bare: true, filename:@name+'.coffee', sourceMap: true, inlineMap: true}
    catch err
      @content[language] = ""
      @exception = err

class exp.JSONDataFile extends exp.File
  constructor: (name, language, extension, source, fileCategory) ->
    super(name, language, extension, "", fileCategory)
    @replaceContent 'default', source

  replaceContent: (language, source) ->
    @dirty = true
    @raw[language] = source
    @content[language] = {}
    @exception = null
    try
      @content[language] = JSON.parse source
    catch e
      @content[language] = {}
      @exception = e
