
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


skills = require('./skill.coffee')

if window?
  window.litexa = window.litexa ? {}
  window.litexa.files = window.litexa.files ? {}
  for k, v of skills
    window.litexa[k] = v
else
  self.litexa = self.litexa ? {}
  self.litexa.files = self.litexa.files ? {}
  for k, v of skills
    self.litexa[k] = v
