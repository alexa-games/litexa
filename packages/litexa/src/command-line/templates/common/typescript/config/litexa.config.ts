/*
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 *  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

const litexaConfiguration: Configuration = {
    name: '{name}',
    deployments: {
        development: {
            module: '@litexa/deploy-aws',
            s3Configuration: { bucketName: '' },
            askProfile: '',
            awsProfile: ''
        }
    },
    plugins: {}
};

export = litexaConfiguration;
