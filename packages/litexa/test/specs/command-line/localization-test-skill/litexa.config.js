'use strict';

module.exports = {
    name: 'localization-test-skill',
    deployments: {
        development: {
            module: '@litexa/deploy-aws',
            S3BucketName: null,
            askProfile: null,
            awsProfile: null
        }
    },
    extensionOptions: {}
};
