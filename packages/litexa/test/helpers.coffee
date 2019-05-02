Test = Test || {};

class Test.MockProjectInfoInterface
  constructor: -> true
  languages: []

class Test.MockTemplateFilesHandlerInterface
  constructor: -> true
  syncDir: -> true

class Test.MockDirectoryCreator
  constructor: -> true
  ensureDirExists: -> true
  create: -> true
  sync: -> true

class Test.MockDirectoryCreatorInterface
  constructor: ->
    return new Test.MockDirectoryCreator()

Test.mockArtifact = { }
class Test.MockArtifactInterface
  constructor: -> true
  saveGlobal: -> Test.mockArtifact

module.exports = Test
