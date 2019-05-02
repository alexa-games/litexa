Test = {}
Test.deploymentTargetConfiguration =
  test:
    accessKeyId: "testAccessKeyId", 
    secretAccessKey: "testSecretAccessKey", 
    region: "testRegion"

  development:
    accessKeyId: "devAccessKeyId", 
    secretAccessKey: "devSecretAccessKey", 
    region: "devRegion"

Test.defaultManifest = 
"""
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
          name: "Some Project"
          summary: "replace with brief description, no longer than 120 characters"
          description: "Longer description, goes to the skill store. 
            Line breaks are supported."
          keywords: [ 
            'game' 
            'fun'
            'single player'
            'modify this list as appropriate' 
          ]
        "en-GB":
          name: "Some Project"
          summary: "replace with brief description, no longer than 120 characters"
          description: "Longer description, goes to the skill store. 
            Line breaks are supported."
          keywords: [ 
            'game' 
            'fun'
            'single player'
            'modify this list as appropriate' 
          ]
    privacyAndCompliance: 
      allowsPurchases: false
      usesPersonalInfo: false
      isChildDirected: false
      isExportCompliant: true
      containsAds: false

      locales: 
        "en-US": 
          privacyPolicyUrl: "http://yoursite/privacy.html",
          termsOfUseUrl: "http://yoursite/terms.html"
        "en-GB": 
          privacyPolicyUrl: "http://yoursite/privacy.html",
          termsOfUseUrl: "http://yoursite/terms.html"
"""

Test.lambdaTriggerStatement =
{
  "Sid":"lc-f3ab8a0a-9c90-4080-9267-1d372a202f6d",
  "Effect":"Allow",
  "Principal":{
    "Service":"alexa-appkit.amazon.com"
  },"Action":"lambda:InvokeFunction",
  "Resource":"arn:aws:lambda:us-east-1:123456789:function:sample_development_litexa_handler:release-0"
}

module.exports = Test
