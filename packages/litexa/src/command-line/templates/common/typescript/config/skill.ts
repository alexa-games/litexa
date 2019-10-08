/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
                privacyPolicyUrl: 'https://www.example.com/privacy.html',
                termsOfUseUrl: 'https://www.example.com/terms.html'
            }
        }
    }
};

export = {
    manifest: skillManifest
};
