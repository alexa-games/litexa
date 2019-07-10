
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


Utils = require('@src/parser/utils').lib
{assert, expect} = require('chai')

describe 'performs string manipulation and checking functions', ->

  it 'trims line breaks', ->
    expect(Utils.replaceNewlineCharacters(null)).to.equal('')
    expect(Utils.replaceNewlineCharacters('hello\nmy name is Ellie', ', ')).to.equal('hello, my name is Ellie')
    expect(Utils.replaceNewlineCharacters('I have a dog', 'meow')).to.equal('I have a dog')

  it 'indicates whether or not a string does not contain non-whitespace text', ->
    assert(Utils.isEmptyContentString(''), 'empty string returns true')
    assert(Utils.isEmptyContentString(' \t\n'), 'whitespace string returns true')
    assert(!Utils.isEmptyContentString(' meow\n'), 'non-empty string returns false')

  it 'indicates if the given index is the first or last index of the given array', ->
    someArr = [500,12,'fish','cat']
    assert(Utils.isFirstOrLastItemOfArray(0, someArr), 'first index returns true')
    assert(!Utils.isFirstOrLastItemOfArray(1, someArr), 'idx in the middle returns false')
    assert(!Utils.isFirstOrLastItemOfArray(-2, someArr), 'negative idx returns false')
    assert(Utils.isFirstOrLastItemOfArray(3, someArr), 'last index returns true')
    assert(!Utils.isFirstOrLastItemOfArray(4, someArr), 'idx > array length returns false')

  it 'deletes leading whitespace for lines', ->
    expect(Utils.cleanLeadingSpaces("""I have a cute cat.
      Her name is Ellie.
      Ellie demands to be petted.
      \tMeow.""")).to.equal('I have a cute cat.\nHer name is Ellie.\nEllie demands to be petted.\nMeow.')
    expect(Utils.cleanLeadingSpaces('Hello hello.\n Hi hi. \nMeow. \t')).to.equal('Hello hello.\nHi hi. \nMeow. \t')

  it 'deletes trailing whitespace for lines', ->
    expect(Utils.cleanTrailingSpaces('Hello hello.\n Hi hi. \nMeow. \t')).to.equal('Hello hello.\n Hi hi.\nMeow. \t')

  it 'dedupes whitespace for each line', ->
    expect(Utils.dedupeNonNewlineConsecutiveWhitespaces('Hello hello.\n Hi hi. \nMeow. \t')).to.equal('Hello hello.\n Hi hi. \nMeow. ')
    expect(Utils.dedupeNonNewlineConsecutiveWhitespaces('  M e o o\to   w www w w  w\t\t\t  \t \thi.')).to.equal(' M e o o\to w www w w w hi.')
