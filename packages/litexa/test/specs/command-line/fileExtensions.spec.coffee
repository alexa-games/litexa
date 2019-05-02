{expect} = require('chai')

fileExtensions = require('@src/command-line/fileExtensions')

describe 'extensions', ->
  it 'supports JavaScript', ->
    expect(fileExtensions['javascript']).to.equal('js')

  it 'supports CoffeeScript', ->
    expect(fileExtensions['coffee']).to.equal('coffee')

  it 'supports JSON', ->
    expect(fileExtensions['json']).to.equal('json')

  it 'supports TypeScript', ->
    expect(fileExtensions['typescript']).to.equal('ts')
