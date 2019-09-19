
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


###

  This file collects documentation sources from around the
  module and creates two outputs:
    * documentation.html at the module root
      this contains all the documentation in a single file

    * additional .md files in the documentation directory
      this contains materials scraped from other sources

  The goal is to have documentation visible in source control
  places that handle .md files elegantly, and to have an easy
  to search local reference once you've pulled the repo.

###


path = require 'path'
fs = require 'fs'
chalk = require 'chalk'


render = ->

  moduleRoot = path.join __dirname, '..', '..'

  makeLinkName = (s) ->
    # convert human readable names into valid url links
    s.replace /\s+/g, '_'

  isCodeLink = (name) ->
    return false unless name[0].toLowerCase() == name[0]
    return true

  # customize marked to collect heading info
  markedLib = require 'marked'
  headings = []
  marked = null
  do ->
    renderer = new markedLib.Renderer()

    renderer.heading = (text, level) ->
      link = makeLinkName text
      headings.push
        level: level
        text: text
        link: link
      return "<h#{level} id='#{link}'>#{text}</h#{level}>"

    marked = (text) -> markedLib text, { renderer: renderer }


  entries = {}
  entryNames = []

  do ->
    pegFilename = path.join moduleRoot, 'parser', 'litexa.pegjs'
    pegSource = fs.readFileSync pegFilename, 'utf8'

    test = /\/\*\s*litexa\s+\[([^\]]+)\]\s+([^*]*\*+(?:[^/*][^*]*\*+)*)\//g
    match = test.exec pegSource
    while match
      name = match[1]
      comment = match[2][0...-1]
      if name of entries
        throw "You have duplicate entry names: #{name}"
      entries[name] =
        text: comment
        name: name
      match = test.exec pegSource

  html = fs.readFileSync path.join(__dirname, 'template.html'), 'utf8'


  do ->
    pages = []

    source = fs.readFileSync path.join(moduleRoot, '..', 'README.md'), 'utf8'
    pages.push marked source

    docsRoot = path.join moduleRoot, 'documentation'
    for file in fs.readdirSync docsRoot
      continue if file == 'reference.md'
      filename = path.join docsRoot, file
      continue if fs.statSync(filename).isDirectory()
      source = fs.readFileSync filename, 'utf8'
      pages.push marked source

    html = html.replace '{pages}', pages.join '\n'


  do ->
    entryHTML = ""
    entryNames = ( n for n of entries )
    entries = ( e for n, e of entries )
    entries.sort (a, b) -> a.name.localeCompare(b.name)

    substituteLinks = (text) ->
      test = /\[([a-zA-Z$@ ]+)\]/
      match = test.exec text
      while match
        name = match[1]
        unless name in entryNames
          console.error chalk.red "missing link [#{name}] in `#{text[0...25]}`"
        link = "<a href='##{makeLinkName name}'>#{name}</a>"
        if isCodeLink name
          link = "<code>#{link}</code>"
        text = text.replace match[0], link
        match = test.exec text
      return text

    headings.push
      level: 1
      text: "Language Reference"
      link: "Language_Reference"
      class: "toc-language-reference"

    for e in entries
      linkName = makeLinkName e.name

      headings.push
        level: 2
        text: e.name
        link: linkName

      contents = e.text
      contents = marked contents
      contents = substituteLinks contents

      namePart = e.name
      if isCodeLink e.name
        namePart = "<code>#{namePart}</code>"

      entryHTML += "
        <tr class='entry'>
          <td id='#{linkName}'
              class='entry-cell entry-name'>#{namePart}</td>
          <td class='entry-cell entry-text'>#{contents}</td>
        </tr>
      "

    html = html.replace '{entries}', entryHTML

  do ->
    tocHTML = []
    links = {}
    level = 1
    for h in headings

      opening = false
      if h.level > level
        tocHTML.push "<ul>"
        opening = true
      else if h.level < level
        tocHTML.push "</ul></li>"
      level = h.level

      if h.link of links
        console.error chalk.red "DUPLICATE LINK detected: #{h.link}"
      links[h.link] = true

      link = "<a href='##{h.link}'>#{h.text}</a>"
      #if isCodeLink h.text
      #  link = "<code>#{link}</code>"

      if opening
        terminator = '</li>'
      else
        terminator = ''

      if h.class?
        tocHTML.push "<li class='#{h.class}'>#{link}#{terminator}"
      else
        tocHTML.push "<li>#{link}#{terminator}"

    while level > 1
      tocHTML.push "</ul></li>"
      level -= 1

    html = html.replace '{toc}', tocHTML.join '\n'


  do ->
    markdownEntries = [
      "# Language Reference\n",
    ]

    substituteLinks = (text) ->
      test = /\[([^\]]+)\]/
      match = test.exec text
      while match
        name = match[1]
        text = text.replace match[0], match[1]
        match = test.exec text
      return text


    for e in entries
      contents = e.text
     #(don't need to do this now) contents = substituteLinks contents

      markdownEntries.push """
      ## #{e.name}

      #{contents}
      """

    outputFilename = path.join moduleRoot, 'documentation', 'reference.md'
    fs.writeFileSync outputFilename, markdownEntries.join('\n'), 'utf8'

  console.log ''
  console.log chalk.green (new Date).toLocaleString()

render()

if process.argv[2] == 'watch'
  docsDir = path.join(__dirname, '../')
  fileCache = {}

  # Takes a string and generates a 32-bit integer
  hash = (contents) ->
    hashedInt = 0
    return hashedInt if contents.length == 0
    for i in [0..contents.length - 1]
      char = contents.charCodeAt(i)
      hashedInt = ((hashedInt << 5) - hashedInt) + char
      hashedInt = hashedInt || 0
    hashedInt

  # Watches for changes
  fs.watch docsDir, (event, file) ->
    filePath = path.join(docsDir, file)
    fileExists = fs.existsSync filePath

    # Ignores extraneous temp data
    if fileExists
      format = 'utf8'

      # hash the file
      data = hash(fs.readFileSync filePath, format)

      # Caches the fingerprint of the data
      fileCache[file] = data unless fileCache[file]?

      # If the contents change, cache contents then re-render the documentation
      if fileCache[file] != data
        fileCache[file] = data
        render()
