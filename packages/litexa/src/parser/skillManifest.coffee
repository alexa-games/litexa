
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


exports.createDefault = ->
  return
    skillManifest:
      manifestVersion: "1.0"
      publishingInformation:
        locales:
          "en-US":
            name: "Project Name"
            summary: "This is a skill summary"
            description: "This is a skill description"
            examplePhrases: [
              "Alexa open hello world"
              "Alexa tell hello world I am Jeff"
              "Alexa tell hello world my name is Peter"
            ]
        isAvailableWorldwide: false
        testingInstructions: "Please test this skill"
        category: "GAMES",
        distributionCountries: ['US', 'GB', 'DE']
        gadgetSupport:
          requirement: "REQUIRED"
          numPlayersMin:2
          numPlayersMax: 2
          minGadgetButtons: 2
          numGadgetButtonsPerPlayer: 2
      privacyAndCompliance:
        allowsPurchases: false
        isExportCompliant: true
        isChildDirected: false
        usesPersonalInfo: false
        containsAds: false
      apis:
        custom:
          endpoint:
            sourceDir: "lambda/custom"
          interfaces: [
            { "type": "GAME_ENGINE" },
            { "type": "GADGET_CONTROLLER" },
            { "type": "RENDER_TEMPLATE" },
            { "type": "AUDIO_PLAYER" }
          ]
