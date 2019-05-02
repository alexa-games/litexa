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
