
# Deploying the skill

Now, you have a working project and are ready to share it
with the world. The next step is to hear it come out of your
own Alexa Device.

We will be using AWS for the deployment of your skill. You
do not need to be familiar with AWS, but if you
continue to use it in deploying Alexa skills, it would be
valuable to learn more about the AWS services your skill
uses.

::: tip AWS is one of many options for deployment
AWS is not required to build skills for Alexa or to use
Litexa. The compiled output could be deployed in any Node.js
compatible environment, but you will be off the beaten path
and starting on a new adventure. 🗺️
:::

## Deployment Prerequisites

Before you deploy your skill, you must have have done the following
(and we'd recommend setting these up in this order, too):

* [Create an Amazon Developer Account](https://developer.amazon.com/alexa-skills-kit)
* [Create an AWS Account](https://aws.amazon.com/)
* [Create a custom IAM Policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_create.html)
  for the deployment user derived from the template below:
  * You will need to replace `myAccountId` and
    `myBucketName` with your [AWS account
    ID](https://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html)
    and desired [S3
    bucket](https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html)
    name, respectively, for it to be valid.
  * <details><summary>Click to show the custom policy template</summary>

    <<< @/docs/book/litexa-iam-policy-template.json

    </details>
* [Create an IAM User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
  with the above custom IAM policy attached. You could name it something like "litexa-deploy".
* [Install the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) and
  [configure it](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) with your
  above IAM User credentials.
* [Install the ASK CLI](https://developer.amazon.com/docs/smapi/quick-start-alexa-skills-kit-command-line-interface.html#install-initialize)
  and sign into your Amazon Developer Account, when prompted during `ask init`. You can choose "Skip" when prompted to select an AWS
  profile to attach (Litexa handles AWS deployment separately).

## Installation

We've created an extension to help you deploy your skill. To install it, run

```bash
npm install -g @litexa/deploy-aws
```

## Setup

Deploying requires some simple setup. In the Litexa configuration you must specify your deployment module, the `s3Configuration.bucketName`
you want to deploy to, your `askProfile`, and your `awsProfile`. By default, Litexa configures your project to deploy with
the `@litexa/deploy-aws` module for the `development` environment and sets the other options to `null`.

```javascript
module.exports = {
    name: '{name}',
    deployments: {
        development: {
            module: '@litexa/deploy-aws',
            s3Configuration: {
                bucketName: null
            },
            askProfile: null,
            awsProfile: null
        }
    },
    extensionOptions: {}
};
```

::: warning NOTE
If your `s3Configuration.bucketName` doesn't exist in your account, litexa will try to create it for you. Note, S3 bucket names create URLs and so are global across users; the one you request here may not be available. You'll see an error come up to that effect, if that's the case.

Your `askProfile` name needs to match one that you configured with `ask init`.

Your `awsProfile` name needs to match one that you configured with `aws configure` and should have the IAM Policy listed above applied to it. Note, litexa can't do this part automatically as it's the policy that grants litexa the ability to access AWS!
:::

## Deploy

To deploy, go to your Litexa project root folder and run

```bash
litexa deploy
```

That's it.

This one command will:

1. Build your project
1. Upload your project assets to your S3 Bucket (and create the specified bucket, if it doesn't exist)
1. Infer your language models
1. Create your skill in the ASK Developer Console
1. Upload your skill manifest to the ASK Developer Console
1. Upload each of your language models to the ASK Developer Console per language region you support
1. Create your Lambda
1. Bundle your project, zip it up, and push it to Lambda
1. Create the DynamoDB table for your skill to save data to

Don't worry if this seems like a lot. You can learn about each of these components in depth later. But now you should be
able to invoke your skill.

Try it out. Invoke your skill on an Alexa device connected to your Alexa account; just say, *"Alexa, open Hello Litexa."*

::: tip Alexa Simulator
If you don't have an Alexa device you can also visit the [ASK Developer Console](https://developer.amazon.com/alexa/console/ask)
and try out your skill in the Alexa Simulator.
:::

