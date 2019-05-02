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
          privacyPolicyUrl: "http://yoursite/privacy.htm",
          termsOfUseUrl: "http://yoursite/terms.htm"

