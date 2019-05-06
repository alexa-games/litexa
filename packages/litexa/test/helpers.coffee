
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
