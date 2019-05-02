const litexaConfiguration: Configuration = {
    name: '{name}',
    deployments: {
        development: {
            module: '@litexa/deploy-aws',
            S3BucketName: '',
            askProfile: '',
            awsProfile: ''
        }
    },
    plugins: {}
};

export = litexaConfiguration;
