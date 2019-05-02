{assert, expect} = require 'chai'

validate = require('@src/command-line/generators/validators/projectNameValidator')

describe '#projectNameValidate', ->
  it 'throws an error if a project name is less than 5 characters', ->
    testFn = -> validate('1234')
    expect(testFn).to.throw('should be at least 5 characters')

  it 'throws an error if it has special characters', ->
    testFn = -> validate('~!@#$%^&*()')
    expect(testFn).to.throw('invalid. You can use letters, numbers, hyphen or underscore characters')

  it 'throws an error if there are any spaces', ->
    testFn = -> validate('this is an invalid name')
    expect(testFn).to.throw("The character ' ' is invalid.")

  it 'does not throw for letters, numbers, hyphen or underscores', ->
    testFn = -> validate("th1s-n4m3s_fine")
    expect(testFn).to.not.throw()

  it 'does not allow backslash and single quotes', ->
    testFn = -> validate("Luis'sErroneousProjectName\\")
    expect(testFn).to.throw('invalid. You can use letters, numbers, hyphen or underscore characters')
