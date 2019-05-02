'use strict';

module.exports = {
    name: '{name}',
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
