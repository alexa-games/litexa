module.exports =
  name: 'button-monte-sample'
  deployments:
    development:
      module: '@litexa/deploy-aws'
      S3BucketName: null
      askProfile: null
      awsProfile: null
  extensionOptions: {}
  # there is no built-in Litexa support for this directive,
  # so declaring it here
  directiveWhitelist: [
    "GadgetController.SetLight"
  ]
