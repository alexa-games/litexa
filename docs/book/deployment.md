# Deployment

*For information on the command line interface, please run `litexa deploy --help`.*

Now that you have a Litexa project generated and working, it is time to deploy it as an Alexa skill.
Deploying your skill is how you can see it in action on a real Alexa-enabled device like an Echo,
or, if you don't have access to one, the ASK Developer Console.

Let's take a look at your Litexa config again. It probably
looks something like this:

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
deployment target. A deployment target is a named
configuration for the deployment of your skill. It determines where, how, and with what settings a
skill will be deployed.

You can name your deployment targets whatever you want and have as many as you want. The `development`
target is just the one `litexa generate` creates for you to get started.

***Why would I want multiple deployment targets?***

The purpose of multiple deployment targets is to allow multiple copies of a skill to
exist at the same time. Each deployment target produces its own isolated skill, independent of
other skills. You may want to use multiple deployment targets to mark stages of your
skill development. For example, you might use the `development` target for active skill development
and adding features. You might then have a `beta-test` target that you share with [beta testers](
  https://developer.amazon.com/docs/custom-skills/skills-beta-testing-for-alexa-skills.html
) so that you can get feedback from potential customers. And finally, you will probably have a
[`production` target](#extra-note-the-production-deployment-target-name) for your public,
customer-facing skill in the Alexa Skill Store.

***Wait a minute, what do you mean by where a skill will be deployed?***

A skill has to live somewhere for it to be accessed. Think of the Alexa-enabled device as a messenger
between your user and your skill. The user says something to their Echo. The Echo passes that message
to its backend, which transforms it into a request to invoke your skill. The backend then sends that
request to wherever your skill lives, much like how a web browser fetches the contents of a website
the user requested.

More specifically, Alexa skill deployment is composed of 2 parts. The first part is deployment of
your skill logic, or backend deployment. The second is your Alexa Skills Kit (ASK) information -
what Alexa needs to know about to build and publish your skill to the Skill Store. This comprises
of your skill model, manifest file, skill ID, and if it exists, monetization metadata.

Going back to your Litexa config, you'll notice that within a deployment target, there is a `module`
field. This field indicates the name of the node module your Litexa skill will use for its backend
deployment. The module implements what sort of hosting, persistent data storage, and logging your
skill code will use during execution. At this time, there is one official deployment module called
`@litexa/deploy-aws`, which is already set in the Litexa config for your convenience. Meanwhile,
Litexa itself performs the second part for you.

Let's talk about each of these two deployment parts in turn.

## Litexa Deploy AWS

This module implements Litexa deployment to Amazon Web
Services, with the following structure:

* Assets are copied into a new or existing S3 bucket of your choice
* Permanent data store is written to a new DynamoDB table
* Skill endpoint is hosted in a Lambda
* Logging is directed to Cloudwatch

### Installation

Run

```bash
npm install -g @litexa/deploy-aws
```

to install this package side by side with
your litexa package. This will then let you specify
`@litexa/deploy-aws` as a deployment module in any
of your projects.

### Authorization

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

:::warning
Bear in mind you want to *keep your aws-config file local* though,
you don't want to be sharing that with other people! We've generated a `.gitignore`
for you that includes it, but if you use a different source code sharing
solution, you may want to configure prevention on uploading this file.
:::

:::tip Diving Deeper on AWS Security
In the long run, it will be beneficial to follow secure credential management
guidelines. For a starting point on what AWS security credentials are, you can begin
[here](https://docs.aws.amazon.com/general/latest/gr/aws-security-credentials.html).
For secure AWS credential management, you may consider reading
[Best Practices for Managing AWS Access Keys](
  https://docs.aws.amazon.com/general/latest/gr/aws-access-keys-best-practices.html)
and [IAM User-specific Credential Management](
  https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html).
:::

There is one more thing you need to set up for authorization, and that is permissions.
AWS permissions are bundled together in what's called a policy. A policy is then attached
to your IAM user, which is the credentials that get used for deployment. To get that set up,
go to the [AWS Permissions section](/book/appendix-aws-permissions.html).

### AWS Configuration

The `@litexa/deploy-aws` module requires you to fill out one more field in your litexa
config called `s3Configuration`. There are also some optional `lambdaConfiguration`
parameters you can put into your configuration for further project customization.

#### S3 Configuration

The deploy module uses S3 to host your skill's assets, which can be sounds and images.
Assets are deployed to the [S3 bucket](
https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html) specified by
`s3Configuration.bucketName` in your Litexa config.

If this bucket doesn't exist yet, the module will automatically create it for you. If
you create your own bucket:

* The bucket itself does not need to be marked public. Individual
files will be marked public on upload.

* The bucket does need to have default CORS correctly configured.
See: [Cross-Origin Resource Sharing (CORS)](
  https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html)

##### Upload Parameters

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

##### S3 Configuration Schema

The schema for the `s3Configuration` object is as follows:

* `bucketName` - (String)
  * The name of the bucket that your assets are deployed to.
* `uploadParams` - (Array\<Object\>) - Optional
  * `filter` - (Array\<String\>) - Optional
    * A list of glob patterns that, when matched to your assets,
      the upload params are applied to.
      * Litexa uses the
      [minimatch NPM package](https://www.npmjs.com/package/minimatch)
      to implement the file pattern matching.
  * `params` - (Object)
    * An object that is passed into Litexa's call on
      the AWS SDK S3 Client's `#upload()` function.
      * To understand what keys are acceptable in the
      `params` object, read more about the AWS SDK S3 Client's
      `#upload()` function in the
      [AWS SDK docs](https://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/S3.html#upload-property).

:::tip You can define default upload params
An `uploadParams` object that either has no `filter` specified, or includes a
`'*'` filter, will be treated as a default set of upload parameters. All
assets that do not match any other filters will use these `params`.
:::

:::tip The order of upload params matters
Any `uploadParams` objects that are not default upload parameters (see above)
are applied in order. This means that individual assets will be set to use the first,
and only the first, matching filter's `params`.
:::

:::warning You may not use the Key, Body, ContentType, and ACL keys
These keys are reserved by Litexa, so you may not use them as part of an
`uploadParams` object. If you attempt to use them, the Litexa deployment
process will fail.
:::

##### Asset Deployment Location

Assets will be deployed to subdirectories of your bucket, isolating
specific deployments of specific projects from each other, copying
the contents of your `litexa/assets` folder to the following location:

```stdout
https://s3.{REGION}.amazonaws.com/{BUCKETNAME}/{SKILLNAME}/{DEPLOYMENTTARGET}/
```

:::warning Use one S3 bucket across your Litexa projects
S3 bucket names are *globally unique*. This means that any AWS account cannot
create a bucket of the same name as an existing bucket until it is deleted.
Your AWS account also has a limit on the number of buckets you can create.
See [here](https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html)
for bucket restrictions and limitations.
:::

Within this location, your assets will be organized by the locales in that folder,
with the assets in the top level going into the `default` folder. So if you have a
Litexa project named `CatsVsCucumbers` and you're deploying the `development` target,
your project folder will look like this locally:

```stdout
.
├── litexa
|   └── assets
|       ├── intro.mp3
|       ├── introScreen.jpg
|       └── en-GB
|           ├── intro.mp3
|           └── resultScreen.jpg
```

And your S3 bucket would look like this:

```stdout
.
├── CatsVsCucumbers
|   └── development
|       ├── default
|       |   ├── intro.mp3
|       |   └── introScreen.jpg
|       └── en-GB
|           ├── intro.mp3
|           └── resultScreen.jpg
```

By default, Litexa will upload Alexa-usable files from your assets directory and
ignore any file types it does not recognize. These files must have the file extensions:
`.png`, `.jpeg`, `.jpg`, `.mp3`, `.json`, or`.txt`. Litexa extensions may add to that list.
Please see the [section on assets](/book/presentation.html#asset-file-references) for more information.

:::tip Overriding a deployment target's assets root path
You can override the skill's assets URL path, instead of using the default S3 path (location of files 
deployed from `litexa/assets`). This can be useful when collaborating on a project with sizable assets, 
to prevent each contributor needing to upload and maintain their own copies of assets.

A deployment target can override the skill asset root path by specifying an `overrideAssetsRoot` URL 
in the Litexa config. For example:

```javascript
const deploymentConfiguration = {
  name: 'my-skill',
  deployments: {
    deployment_target_name: {
      module: '@litexa/deploy-aws',
      overrideAssetsRoot: 'https://path.com/to/your/assets/'
    }
  }
}
```
:::

:::tip Skipping Litexa's asset reference validation
Litexa will validate asset references for certain keywords (`card`, `screen`, `soundEffect`, etc.) and fail 
Litexa tests if those assets aren't found in the `litexa/assets` directory. This validation can be 
disabled per deployment target, when referenced assets are missing locally (which is typically the 
case when `overrideAssetsRoot` is used).

A deployment target can skip asset reference validation by setting disableAssetReferenceValidation in the 
Litexa config. For example:

```javascript
const deploymentConfiguration = {
  name: 'my-skill',
  deployments: {
    deyployment_target_name: {
      module: '@litexa/deploy-aws',
      overrideAssetsRoot: 'https://path.com/to/your/assets/',
      disableAssetReferenceValidation: true
    }
  }
}
```
:::

#### Lambda Configuration (optional)

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

### CloudWatch Logging

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

:::tip Use the log command in development, not production
If your skill becomes popular, running `litexa logs` may produce very large log files of requests and responses
happening in parallel. That may make it difficult to trace a single skill interaction. It may also cause a
significant performance hit while it is running. We recommend using the command for when you are testing
your skill on a device or the simulator instead.
:::

It is safe (won't cause Litexa project issues) to delete the `.logs` directory and any files within.

For more information on the log command line interface, please run `litexa logs --help`.

### Local Caching of Deployment Artifacts

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

## ASK Deployment

Now that we've covered the backend deployment, we can now cover the Alexa Skills Kit (ASK)
part of deployment. As a reminder, ASK deployment consist of the artifacts that Alexa needs
to know about to build and publish your skill to the Skill Store.

### Authorization

Please install the [ask-cli](https://developer.amazon.com/docs/smapi/quick-start-alexa-skills-kit-command-line-interface.html)
first and create an ASK profile associated with your Amazon developer account.

You'll notice that the Litexa config has one field we haven't discussed yet, which is the `askProfile` field. Please set
that field with the name of the ASK profile you want to use for your skill.

:::tip Congrats! You are ready to deploy your skill.
You are now set to deploy your skill! If you run `litexa deploy`, it will deploy the `development` target of your skill. It
will go through the backend deployment first, and if it succeeds, will continue on to deploy the ASK information.
When this is complete, you can invoke your skill on an Alexa-enabled device or the skill simulator in the ASK Developer Console.
If you want to know what Litexa is doing for ASK deployment, then read on.
:::

### Deployment Details and Artifacts

Under the hood, Litexa uses the Skill Management API, or SMAPI, to deploy your skill, using your designated `askProfile`
in the Litexa config. It constructs and deploys 2 ASK Developer Console artifacts for you: the skill manifest and model files.
*Because it manages backend deployment separately by using the `module` specified in the Litexa config, it actually does not
rely on the configured AWS profile that you may have associated with your ASK profile.*

If this is your first time deploying to that deployment target, it will create a new skill for you
and save the skill ID in `artifacts.json`. Note that `artifacts.json` replaces the `.ask/config` you would use
normally if you invoked the ask-cli directly. It is the source of your skill ID, so *if you delete your skill ID,
Litexa will treat your deployment target as a new skill deployment*. Otherwise, if you have a skill ID, Litexa will
update that skill.

:::tip Best Practices on Account Management
Because Litexa requires a developer account for deployment, we
recommend looking at documentation for [Developer Account Management](
  https://developer.amazon.com/docs/app-submission/manage-account-and-permissions.html)
and [best practices](
  https://developer.amazon.com/docs/smapi/ask-cli-intro.html#team-account-management-best-practice),
especially if you are working in a team.
:::

### Skill Manifest File

A skill manifest is your skill's metadata. It contains customer-facing information about the skill, such as the
description and privacy policy, and Alexa-specific information, such as which APIs your skill needs to access.
Skill developers can provide this information via a skill manifest file + SMAPI, or
by filling out the information manually in the ASK Developer Console.

Litexa takes your `skill.coffee/js/ts` (we might refer to this as `skill.*` in documentation) and Litexa config file
to create your skill manifest file. You can find the constructed skill manifest file after a deployment
in `.deploy/{yourDeploymentTarget}/skill.json`.

If you use any Litexa extensions in your project, they may add the APIs they use to your skill manifest automatically.
Otherwise, you will need to add the required fields to your `skill.*`. Likewise, if you use an API Litexa does not
explicitly support (e.g. Gadget Controller), you will need to add it to your `skill.*`.

#### Deployment Target Overrides

If you want to change your skill manifest based on a specific deployment target, you can do so by keying the original
manifest content structure on the deployment target name. This is completely optional - any unkeyed targets will fall
back to using the default manifest.

For example, the below `skill.js` has a different manifest for its `QA` deployment target only.

```javascript
const standardSkillManifest = { /* ... */ };
const qaSkillManifest = { /* ... */ };

module.exports = {
  manifest: standardSkillManifest // default manifest
  QA: {
    manifest: qaSkillManifest // "QA" deployment target-specific manifest
  }
}
```

### Skill Model

A custom interaction model, also referred to as a language model or skill model, is a contract that defines the voice
interface your skill will accept and your customers will use, for each locale. The skill model consists of the
invocation name, intents, utterances, and slots. Please see the [interaction model documentation](
  https://developer.amazon.com/docs/custom-skills/create-the-interaction-model-for-your-skill.html) for definitions
of these terms.

Litexa builds the skill model from your skill invocation name in the `skill.*` file and the intent handlers you have
defined in your `*.litexa` code by aggregating all case-sensitive unique intents and slots, and adding any required
intents for your project's litexa extensions.

It also adds the AMAZON.StopIntent, AMAZON.CancelIntent, and AMAZON.StartOverIntent intents to your model if you don't
already handle them. The Stop and Cancel intents will simply end the skill session (equivalent to `END` behind
the scenes), and the Start Over intent will automatically take your skill back to its launch state (equivalent to
`-> launch` behind the scenes).

Implementing these intent handlers will override these default behaviors with the additional requirements:

* for StopIntent and CancelIntent, you will need to explictly state one of the `LISTEN` controls to override the implicit `END`
* for StartOverIntent, you will need to explicitly specify a new `->` transition, to replace the implicit `-> launch`

After a deployment, you can find the constructed model file in
`.deploy/{yourDeploymentTarget}/model-{locale}.json`. For example, it may be `.deploy/development/model-en-US.json`.

#### Alternate Skill Invocation Name (optional)

All Alexa skills require an invocation name that users say in order to launch the
skill. Invocation names are built into the skill model. These names are not unique -
the Alexa-enabled device's backend determines which skill gets invoked for the user,
which is opaque to both the user and skill developer. If you are developing a skill
with multiple deployment targets and they all have the same invocation name, it may
be difficult to know which skill was invoked when you test it.

Litexa offers configuration to change invocation names for each deployment target.

The first is an `invocation` field. It maps a supported locale in your project's `skill.*`
to the invocation name you put in it.

The second is a `invocationSuffix` field. It is a string suffix that is
automatically appended to the end of your skill invocation name.

Here's an example. Let's say your skill's invocation names in en-US and en-GB are both
`cats versus cucumbers`. If you add an alternate invocation name to just en-GB in your
`development` deployment target, your Litexa config will look like this:

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
      "invocation": {
        "en-GB": "cloudy cats"
      }
    }
  }
}
```

With this setting, your skill invocation name in en-GB will be `cloudy cats` while the one in
en-US will remain `cats versus cucumbers`.

If you instead add an invocation suffix, your Litexa config will look like this:

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
      "invocationSuffix": "dev"
    }
  }
}
```

And both locales will have the invocation name `cats versus cucumbers dev`.

If you provide both fields, your skill invocation name for that locale will have both.
Combining the above examples will net you `cloudy cats dev` in en-GB and
`cats versus cucumbers dev` in en-US.

Once again, you can view the result skill invocation names in the deployed model files at
`.deploy/{yourDeploymentTarget}/model-{locale}.json`.

### Deployment Target-based Skill Configuration

You can change the skill behavior and language model based on the deployment target you
are executing tests or deploying the skill for. Please see [DEPLOY variables](
/book/expressions.html#deploy-variables) for more information.

### Monetization

Please see the [Monetization chapter](/book/monetization.html).

## Extra Note: Including `production` in the Deployment Target Name

There is a special condition on deployment target names. If the name does *not*
have the word `production` in it, a ` (<target>)` will be automatically
appended to the name of your skill, with `<target>` being the name of the
deployment target you used to deploy the skill. We recommend labeling only
your production skill deployment target(s) with `production`.

:::tip
We recommend changing the DynamoDB settings for your live skill to ensure that it does not
throttle your skill's persistent storage read and writes, which would have an impact of added
latency for your customers. Increasing the provisioned capacity units, enabling Auto Scaling,
or switching the table to On-Demand capacity are all ways you can make your skill's experience
more robust.

See [DynamoDB Capacity Modes](
  https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadWriteCapacityMode.html
) for more information.
:::

## Relevant Resources

* [AWS permissions](/book/appendix-aws-permissions.html) for setting up your IAM user with the
required permissions.
* [Default AWS Settings](/book/appendix-default-aws-settings.html) for details on the configurations
`@litexa/deploy-aws` sets up your AWS resources with.
