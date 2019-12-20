# Litexa Deploy AWS

*NOTE: For full documentation on deployment, please see the book.
For information on the command line interface, please run
`litexa deploy --help`.*

This module implements Litexa deployment to Amazon Web
Services, with the following structure:

* Assets are copied into a new or existing S3 bucket of your choice
* Permanent data store is written to a new DynamoDB table
* Skill endpoint is hosted in a Lambda
* Logging is directed to Cloudwatch

## Before You Start

Let's take a closer look at your Litexa config (the `litexa.config.js/ts/json/coffee` in your project
root). It probably looks something like this:

```json
{
  "deployments": {
    "development": {
      "module": "@litexa/deploy-aws",
      "s3Configuration": {
        "bucketName": "suncoast-assets"
      },
      "askProfile": "suncoast",
      "awsProfile": "prototyping"
    }
  }
}
```

You will see that there is a key called `development` under the `deployments` key. This is called a
deployment target. A deployment target is a named configuration for the deployment of your skill.
It determines where, how, and with what settings a skill will be deployed.

You can name your deployment targets whatever you want and have as many as you want. The `development`
target is just the one `litexa generate` creates for you to get started.

Alexa skill deployment is comprised of 2 parts. The first part is deployment of your skill logic,
or backend deployment. This is what a deploy module takes care of for you, and what this README will be
about. For the second part, read the `litexa` module's README or the Book's chapter on ASK deployment.

In your Litexa config, you'll notice that within a deployment target, there is a `module` field.
This field indicates the name of the node module your Litexa skill will use for its backend
deployment. The module implements what sort of hosting, persistent data storage, and logging your
skill code will use during execution. At this time, there is one official deployment module called
`@litexa/deploy-aws` (this one!), which is already set in the Litexa config for your convenience.

## Installation

Run

```bash
npm install -g @litexa/deploy-aws
```

to install this package side by side with
your litexa package. This will then let you specify
`@litexa/deploy-aws` as a deployment module in any
of your projects.

## Authorization

AWS access is piped through the aws-sdk module (installed as a `@litexa/deploy-aws`
node_module dependency), so all of its configuration mechanisms are supported
, e.g. setting environment variables.

The simplest way to authorize AWS is to complete the aws-cli
installation, and then use the profile name you set up
in the `awsProfile` field in your Litexa config.

See: [Installing the AWS CLI](
  https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) for
more information.

You can alternatively provide credentials local to a particular project
by creating a `aws-config.json` file in your project root containing
the following credentials:

```json
{
  "development": {
    "accessKeyId": "someAccessKeyId",
    "secretAccessKey": "theSecretAccessKeyForThatAccessKeyId",
    "region": "us-east-1"
  }
}
```

where `development` is the name of the deployment target you want this configuration
for.

*Implementation detail: If you have neither an `awsProfile` field in your Litexa config
nor a local `aws-config.json` file, `@litexa/deploy-aws` will attempt to use the
aws-cli profile named `default`.*

Bear in mind you want to *keep your aws-config file local* though,
you don't want to be sharing that with other people! We've generated a `.gitignore`
for you that includes it, but if you use a different source code sharing
solution, you may want to configure prevention on uploading this file.

There is one more thing you need to set up for authorization, and that is permissions.
AWS permissions are bundled together in what's called a policy. A policy is then attached
to your IAM user, which is the credentials that get used for deployment. To get that set up,
go to the [AWS Permissions section](#aws-permissions).

### Diving Deeper on AWS Security

In the long run, it will be beneficial to follow secure credential management
guidelines. For a starting point on what AWS security credentials are, you can begin
[here](https://docs.aws.amazon.com/general/latest/gr/aws-security-credentials.html).
For secure AWS credential management, you may consider reading
[Best Practices for Managing AWS Access Keys](
  https://docs.aws.amazon.com/general/latest/gr/aws-access-keys-best-practices.html)
and [IAM User-specific Credential Management](
  https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html).

## AWS Configuration

This deploy module requires you to fill out one more field in your litexa
config called `s3Configuration.bucketName`. There are also some optional `LambdaConfiguration`
parameters you can put into your configuration for further project customization.

### S3 Configuration

The deploy module uses S3 to host your skill's assets, which can be sounds and images.
Assets are deployed to the [S3 bucket](
  https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html) with the name you
put in the `s3Configuration.bucketName` field in your Litexa config.

If this bucket doesn't exist yet, the module will automatically create it for you. If
you create your own bucket:

* The bucket itself does not need to be marked public. Individual
files will be marked public on upload.

* The bucket does need to have default CORS correctly configured.
See: [Cross-Origin Resource Sharing (CORS)](
  https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html)

#### Upload Parameters

You can specify S3 upload parameters to groups of your assets by utilizing the
optional `s3Configuration.uploadParams` object list.

A Litexa config that utilizes `s3Configuration.uploadParams` might look like:

```javascript
const deploymentConfiguration = {
  name: 'my-skill',
  deployments: {
    production: {
      module: '@litexa/deploy-aws',
      s3Configuration: {
        bucketName: 'my-skill-bucket',
        uploadParams: [
          {
            filter: ['*.mp3'],
            params: {
              // check for file change every 10 minutes
              // (useful for content files that are regularly updated)
              CacheControl: 'max-age=600'
            }
          },
          {
            filter: ['*.jpg', '*.png'],
            params: {
              // always check for file change
              // (useful during development)
              CacheControl: 'no-cache'
            }
          },
          {
            params: {
              // no file filter -> applies 1 hour age
              // to all files that aren't caught by the
              // above 2 filters
              CacheControl: 'max-age=3600'
            }
          }
        ]
      }
    }
  }
}
```

#### S3 Configuration Schema

The schema for the `s3Configuration` object is as follows:

* `bucketName` - (String)
  * The name of the bucket that your assets are deployed to.
* `uploadParams` - (Array\<Object\>) - Optional
  * `filter` - (Array\<String\>) - Optional
    * A list of glob patterns that, when matched to your assets,
      the upload params are applied to. Litexa uses the
      [minimatch NPM package](https://www.npmjs.com/package/minimatch)
      to implement the file pattern matching.
  * `params` - (Object)
    * An object that is passed into Litexa's call on
      the AWS SDK S3 Client's `#upload()` function.
      * To understand what keys are acceptable in the
      `params` object, read more about the AWS SDK S3 Client's
      `#upload()` function in the
      [AWS SDK docs](https://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/S3.html#upload-property).

**Tip: The order of elements inside of uploadParams matters.
The `uploadParams` object array is a logical pipeline of filters. The
filters will be applied to your assets in the order that they are
defined in your Litexa configuration. Once a filter has been applied
to a set of assets, those assets are removed from the pipeline, so
subsequent filters will not be applied; subsequent filters will not
override a previous filter.**

**Tip: You can define default upload params.
An `uploadParams` object with a `filter` property that is either
not defined or has a value of `'*'` will be treated as a default
set of upload parameters. All assets that do not match any other
filter will have this one applied to them.**

**Warning: You may not use the `Key`, `Body`, `ContentType`, and `ACL` keys
as part of an `uploadParams` object. If you attempt to use them, the
Litexa deployment process will fail.**

#### Asset Deployment Location

Assets will be deployed to subdirectories of your bucket, isolating
specific deployments of specific projects from each other, copying
the contents of your `litexa/assets` folder to the following location:

    https://s3.{REGION}.amazonaws.com/{BUCKETNAME}/{SKILLNAME}/{DEPLOYMENTTARGET}/

**Note: Use one S3 bucket across your Litexa projects.**

S3 bucket names are *globally unique*. This means that any AWS account cannot
create a bucket of the same name as an existing bucket until it is deleted.
Your AWS account also has a limit on the number of buckets you can create.
See [here](https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html)
for bucket restrictions and limitations.

Within this location, your assets will be organized by the locales in that folder,
with the assets in the top level going into the `default` folder. So if you have a
Litexa project named `CatsVsCucumbers` and you're deploying the `development` target,
your project folder will look like this locally:

    .
    ├── litexa
    |   └── assets
    |       ├── intro.mp3
    |       ├── introScreen.jpg
    |       └── en-GB
    |           ├── intro.mp3
    |           └── resultScreen.jpg

And your S3 bucket would look like this:

    .
    ├── CatsVsCucumbers
    |   └── development
    |       ├── default
    |       |   ├── intro.mp3
    |       |   └── introScreen.jpg
    |       └── en-GB
    |           ├── intro.mp3
    |           └── resultScreen.jpg

By default, Litexa will upload Alexa-usable files from your assets directory and
ignore any file types it does not recognize. These files must have the file extensions:
`.png`, `.jpeg`, `.jpg`, `.mp3`, `.json`, or`.txt`. Litexa extensions may add to that list.

### Lambda Configuration (optional)

The `@litexa/deploy-aws` module deploys your skill to AWS Lambda. It sets a few defaults,
but you are welcome to override these settings with your own in the Litexa config. Here
is an example with all the supported Lambda configuration options:

```json
{
  "deployments": {
    "development": {
      "module": "@litexa/deploy-aws",
      "s3Configuration": {
        "bucketName": "suncoast-assets"
      },
      "askProfile": "suncoast",
      "awsProfile": "prototyping",
      "lambdaConfiguration": {
        "MemorySize": 128,
        "Timeout": 240,
        "Environment": {
          "Variables": {
            "mySpecialVariable": 13
          }
        }
      }
    }
  }
}
```

The `lambdaConfiguration` object gets merged into the generated configuration
that will be used to call Lambda's [updateFunctionConfiguration](
  https://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/Lambda.html#updateFunctionConfiguration-property).
You can use this to modify the Lambda's timeout, change the memory size, or
add your own environment variables. All sub keys are optional.

## CloudWatch Logging

Litexa uses an environment variable called `loggingLevel` to determine what to log. In
this deploy module, logs are recorded in CloudWatch Logs. There are 3 possible values
you can set for this variable:

* `terse`: This is the default setting. Will log the relevant part of the skill request and the full skill response.
* `verbose`: Will log the full skill request and the full skill response.
* (empty string): Will not log skill requests and responses.

See the [Lambda Configuration](#lambda-configuration-optional) section above for how to set this variable.

If you have any logging output in your litexa project though, those will still be logged to CloudWatch
independently of this setting.

You can retrieve your logs via the `litexa logs` command for a specified deployment target. This will retrieve
logs after the timestamp of the command itself. The deploy module
will download your skill's CloudWatch Logs and format them as skill requests and responses. The downloaded
logs will be available in the project's `.logs/{DEPLOYMENTTARGET}` directory.

### Use the log command in development, not production

If your skill becomes popular, running `litexa logs` may produce very large log files of requests and responses
happening in parallel. That may make it difficult to trace a single skill interaction. It may also cause a
significant performance hit while it is running. We recommend using the command for when you are testing
your skill on a device or the simulator instead.

It is safe (won't cause Litexa project issues) to delete the `.logs` directory and any files within.

For more information on the log command line interface, please run `litexa logs --help`.

## Local Caching of Deployment Artifacts

A deployment will use a directory named after that deployment target
inside the project's ephemeral `.deploy` directory to cache intermediate
files before uploading, as well as additional files to aid in debugging
deployed artifacts.

For speed, the local cache usually doesn't validate the contents of
the `.deploy` directory, and builds incremental changes on top of it.
If you have modified this directory in any way, deploy results
are *undefined*.

Conversely, you can safely delete each deployment target directory inside
the `.deploy` directory at any time; this module will detect the cache as
empty and rebuild it as necessary. If you'd like to delete all deployment caches,
you can also just delete the `.deploy` directory.

If you modify the contents of your Litexa config during
development, Litexa will automatically wipe the `.deploy` and
`.test` temporary directories to perform a clean deployment.

## Extra Note: The `production` Deployment Target Name

There is a special deployment target name called `production`.
For deployment targets that are *not* this, a `\ (development)` will be
automatically appended to the name of your skill, with `development`
specified as your named deployment target. We recommend creating and
using this deployment target for your live skill.

**Also:**

We recommend changing the DynamoDB settings for your live skill to ensure that it does not
throttle your skill's persistent storage read and writes, which would have an impact of added
latency for your customers. Increasing the provisioned capacity units, enabling Auto Scaling,
or switching the table to On-Demand capacity are all ways you can make your skill's experience
more robust.

See [DynamoDB Capacity Modes](
  https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadWriteCapacityMode.html
) for more information.

## Default AWS Settings

This module configures the following settings:

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
* * loggingLevel = `terse`

## S3

* If the `litexa deploy` command generates a bucket for you, it does so with all default settings.
* Objects in the bucket will be marked public on upload.

## CloudWatch Logs

* If the Lambda's log group doesn't exist yet (will be the case for a newly-generated Lambda),
it will create it and then apply a 30 day retention policy to it.

## AWS Permissions

Your IAM user will require the following [minimum permissions](#minimum-permissions). You can [create a
custom policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_create.html) to define
these permissions and attach it to your user. There is a [sample policy](#sample-policy-document) at
the end you can use and modify for your own account.

### IAM

The following permissions all apply to the role `litexa_handler_lambda`.

* AttachRolePolicy
* CreateRole
* GetRole
* ListAttachedRolePolicies
* PassRole

### Lambda

The following permissions all apply to the Lambda function name structure
`*_*_litexa_handler`, where `*` is a wildcard.

* AddPermission
* CreateAlias
* CreateFunction
* GetAlias
* GetFunctionConfiguration
* GetPolicy
* ListAliases
* RemovePermission
* UpdateFunctionCode
* UpdateFunctionConfiguration

### DynamoDB

The following permissions all apply to the DynamoDB table name structure
`*_*_litexa_handler_state`, where `*` is a wildcard.

* CreateTable
* DescribeTable

### S3

This permission automatically applies to all resources.

* ListAllMyBuckets

The following permissions apply to the S3 bucket defined in the
`s3Configuration.bucketName` field in your litexa.config.coffee/js/ts/json file.

* CreateBucket
* ListBucket

The following permissions apply to all objects in the S3 bucket defined
in the `s3Configuration.bucketName` field in your litexa.config.coffee/js/ts/json file.

* PutObject
* PutObjectAcl

### CloudWatch Logs

This permission applies to all Cloudwatch log groups.

* DescribeLogGroups

This permission automatically applies to all resources.

* CreateLogGroup

These permissions apply to CloudWatch log streams with the
log group name structure `*_*_litexa_handler,` where `*` is a wildcard.

* DescribeLogStreams
* PutRetentionPolicy

This permission requires the above resource plus wildcards for the log stream
and log stream name sections.

* GetLogEvents

### Minimum Permissions

Any resources with wildcards `*` can be replaced by the specific ARN,
but the wildcards are practical for creating multiple Litexa projects
in the same AWS account.

## Sample Policy Document

Remember to replace `myAccountId` and `myBucketName` with your AWS
account ID number and S3 bucket, respectively.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "IAMRole",
            "Effect": "Allow",
            "Action": [
                "iam:AttachRolePolicy",
                "iam:CreateRole",
                "iam:GetRole",
                "iam:ListAttachedRolePolicies",
                "iam:PassRole"
            ],
            "Resource": "arn:aws:iam::myAccountId:role/litexa_handler_lambda"
        },
        {
            "Sid": "Lambda",
            "Effect": "Allow",
            "Action": [
                "lambda:AddPermission",
                "lambda:CreateAlias",
                "lambda:CreateFunction",
                "lambda:GetAlias",
                "lambda:GetFunctionConfiguration",
                "lambda:GetPolicy",
                "lambda:ListAliases",
                "lambda:RemovePermission",
                "lambda:UpdateFunctionConfiguration",
                "lambda:UpdateFunctionCode"
            ],
            "Resource": "arn:aws:lambda:*:myAccountId:function:*_*_litexa_handler"
        },
        {
            "Sid": "DynamoDB",
            "Effect": "Allow",
            "Action": [
                "dynamodb:CreateTable",
                "dynamodb:DescribeTable"
            ],
            "Resource": "arn:aws:dynamodb:*:myAccountId:table/*_*_litexa_handler_state"
        },
        {
            "Sid": "CreateLogGroupListS3Buckets",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "s3:ListAllMyBuckets"
            ],
            "Resource": "*"
        },
        {
            "Sid": "S3BucketActions",
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::myBucketName"
        },
        {
            "Sid": "S3BucketObjectActions",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": "arn:aws:s3:::myBucketName/*"
        },
        {
            "Sid": "DescribeLogGroups",
            "Effect": "Allow",
            "Action": "logs:DescribeLogGroups",
            "Resource": "arn:aws:logs:*:myAccountId:log-group:*"
        },
        {
            "Sid": "LogStreamActions",
            "Effect": "Allow",
            "Action": [
              "logs:DescribeLogStreams",
              "logs:PutRetentionPolicy"
            ],
            "Resource": "arn:aws:logs:*:myAccountId:log-group:/aws/lambda/*_*_litexa_handler:log-stream:"
        },
        {
            "Sid": "GetLogEvents",
            "Effect": "Allow",
            "Action": "logs:GetLogEvents",
            "Resource": "arn:aws:logs:*:myAccountId:log-group:/aws/lambda/*_*_litexa_handler:*:*"
        }
    ]
}
```
