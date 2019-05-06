/*
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved. 
 * These materials are licensed as "Restricted Program Materials" under the Program Materials 
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service. 
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html. 
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized 
 * terms not defined in this file have the meanings given to them in the Agreement. 
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const skillManifest: Manifest = {
    publishingInformation: {
        isAvailableWorldwide: false,
        distributionCountries: ['US'],
        distributionMode: 'PUBLIC',
        category: 'GAMES',
        testingInstructions: 'replace with testing instructions',
        locales: {
            'en-US': {
                name: '{name}',
                invocation: '{invocation}',
                summary: 'replace with brief description, no longer than 120 characters',
                description: 'Longer description, goes to the skill store. Line breaks are supported.',
                examplePhrases: [
                    'Alexa, launch {invocation}',
                    'Alexa, open {invocation}',
                    'Alexa, play {invocation}',
                ],
                keywords: [
                    'game',
                    'fun',
                    'single player',
                    'modify this list as appropriate'
                ]
            }
        }
    },
    privacyAndCompliance: {
        allowsPurchases: false,
        usesPersonalInfo: false,
        isChildDirected: false,
        isExportCompliant: true,
        containsAds: false,
        locales: {
            'en-US': {
                privacyPolicyUrl: 'http://yoursite/privacy.html',
                termsOfUseUrl: 'http://yoursite/terms.html'
            }
        }
    }
};

export = {
    manifest: skillManifest
};
