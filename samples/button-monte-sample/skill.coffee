
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
  This is a sample skill manifest for Button Monte.
###

module.exports =
  manifest:
    publishingInformation:
      isAvailableWorldwide: false,
      distributionCountries: [ 'US' ]
      distributionMode: 'PUBLIC'
      category: 'GAMES'
      testingInstructions: "Grab at least 2 echo buttons and follow the prompts."

      locales:
        "en-US":
          name: "Button Monte Sample"
          invocation: "button monte sample"
          summary: "Can you keep up with the trickster’s lightning fast hands? Will you be more skillful when the tables have turned? Try your luck at this sleight of hand game."
          # You don't have to, but a good description contains the game's requirements,
          # a flavored description of the skill, and then instructions on how to play.
          description: """This game requires at least 2 Echo Buttons. Echo Buttons offer a new way
            to play game skills through your compatible Echo device. To learn more just ask
            \"Alexa, what are Echo Buttons?\"\n\nCan you keep up with the trickster’s lightning
            fast hands? Will you be more skillful when the tables have turned?  Try your luck at
            this classic sleight of hand game, for 2 players.\n\nOne player is the Watcher, and
            the other is the Trickster. Watcher keeps an eye on the red button. Trickster shuffles
            the buttons around. As soon as the buttons turn green, Watcher presses the one thought
            to be the red button."""
          examplePhrases: [
            "Alexa, launch Button Monte Sample"
            "Alexa, open Button Monte Sample"
            "Alexa, play Button Monte Sample"
          ]
          keywords: [
            "Echo Button",
            "Echo Button Skills",
            "Buttons",
            "game buttons",
            "toy",
            "gadget",
            "quick",
            "multiplayer",
            "trick"
          ]
      # required section for echo button skills
      gadgetSupport:
        requirement: "REQUIRED",
        numPlayersMin: 2,
        numPlayersMax: 2,
        minGadgetButtons: 2,
        maxGadgetButtons: 4
    privacyAndCompliance:
      allowsPurchases: false
      usesPersonalInfo: false
      isChildDirected: false
      isExportCompliant: true
      containsAds: false
      # there is no privacy policy and TOS for this skill sample
    apis:
      custom:
        interfaces: [
          {
            type: "GADGET_CONTROLLER" # declaring this one explicitly since we don't have a litexa extension that does it for us
          }
        ]
