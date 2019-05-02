# Appendix: Default AWS Settings

On `litexa deploy`, the `@litexa/deploy-aws` module configures the following settings
for backend deployment:

## IAM

* Creates an IAM role called *litexa_handler_lambda* for your Lambda to use.
It has the policies: **CloudWatchFullAccess**, **AmazonDynamoDBFullAccess**, and **AWSLambdaBasicExecutionRole**.

## DynamoDB

* Provisioned read capacity units: 10 (Auto Scaling Disabled)
* Provisioned write capacity units: 10 (Auto Scaling Disabled)
* Primary key is a String called `userId` - the `litexa` module
gives this the skill requests's `context.System.device.deviceId` field, by default.

## Lambda

* Creates/uses an alias, which is included as part of the skill endpoint
* The deployment target's alias is set to point to `$LATEST` on every deployment
* Memory size of 256 MB
* 10 second timeout (maximum runtime)
* Some environment variables related to your skill configuration
  * loggingLevel = `terse`

## S3

* If the `litexa deploy` command generates a bucket for you, it does so with all default settings.
* Objects in the bucket will be marked public on upload.

## CloudWatch Logs

* If the Lambda's log group doesn't exist yet (will be the case for a newly-generated Lambda),
it will create it and then apply a 30 day retention policy to it.
