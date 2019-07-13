###
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###

module.exports =
  manifest:
    publishingInformation:
      isAvailableWorldwide: false,
      distributionCountries: [ 'US' ]
      distributionMode: 'PUBLIC'
      category: 'GAMES'
      testingInstructions: "replace with testing instructions"


      locales:
        "en-US":
          name: "monetization test"
          invocation: "monetization test"
          summary: "replace with brief description, no longer than 120 characters"
          description: """Longer description, goes to the skill store.

            Line breaks are supported."""
          examplePhrases: [
            "Alexa, launch test monetization"
            "Alexa, open test monetization"
            "Alexa, play test monetization"
          ]
          keywords: [
            'monetization'
          ]

    privacyAndCompliance:
      allowsPurchases: false
      usesPersonalInfo: false
      isChildDirected: false
      isExportCompliant: true
      containsAds: false

      locales:
        "en-US":
          privacyPolicyUrl: "https://www.example.com/privacy.htm",
          termsOfUseUrl: "https://www.example.com/terms.htm"
