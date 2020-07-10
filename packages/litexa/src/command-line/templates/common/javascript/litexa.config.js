/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

'use strict';

module.exports = {
    name: '{name}',
    deployments: {
        development: {
            module: '@litexa/deploy-aws',
            useSessionAttributesForPersistentStore: false,
            s3Configuration: {
                bucketName: null
            },
            askProfile: null,
            awsProfile: null
        }
    },
    extensionOptions: {}
};
