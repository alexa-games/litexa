# Getting Started with Litexa

This guide covers how to get up and running with Litexa.

After reading this guide you'll know:

<span style="color:#00caff">&#10004;</span> How to generate a new Litexa project<br/>
<span style="color:#00caff">&#10004;</span> The anatomy of a Litexa project<br/>
<span style="color:#00caff">&#10004;</span> How to run, modify, and test your code<br/>
<span style="color:#00caff">&#10004;</span> How to deploy your code<br/>
<span style="color:#00caff">&#10004;</span> Where you can go to learn more about Litexa<br/>

## Guide Assumptions

This guide is designed for anyone wanting to write [Alexa
Skills](https://developer.amazon.com/alexa-skills-kit). It does not assume familiarity with Alexa
Skill building, but it does assume some knowledge of programming. Any code examples you may see
during this guide are written in JavaScript and run on Node.js. As a result, if you are not familiar
with JavaScript and Node.js you might find you have a steep learning curve. There are several
resources online to help you learn JavaScript and Node.js:

* [Installing NPM](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)
* [Node.js Guides](https://nodejs.org/en/docs/guides/)
* [JavaScript](https://javascript.info/)
* [YDKJS](https://github.com/getify/You-Dont-Know-JS)

The primary way you'll interact with Litexa will be through the command-line; it would also
be helpful to be comfortable with command-line interface (CLI) tooling.

## What is Litexa?

Litexa is both a framework and a language for writing Alexa skills. The framework lets you define, test, and deploy your
language model, your skill handler, and any associated assets. The language is a convenient domain-specific language (DSL)
that allows you to focus on the logic and presentation of your skill over utility code to interact with Alexa.

::: tip Wait, why do I need Node.js?
Litexa is a DSL that compiles down to performant and ES5 compliant JavaScript that runs on Node.js.

While you could write your skill solely in the Litexa language, it is not meant to be general purpose. In fact, you'll
often want to incorporate external code and dependencies alongside your skill logic in Litexa.
:::

## Install

### Prerequisites

* Operating Systems: We know that the following operating
  systems work fine, but any OS that runs the supported
  version of Node.js is a candidate.
  * Mac OS - Sierra, High Sierra, Mojave
  * Windows 10 x64
  * Linux - Ubuntu (14, 16, 18)
* Development
  * [Node.js](https://nodejs.org/) version
    <strong>8.11</strong> or higher

### Installation Steps

Litexa is a command line utility that is installed as a global npm package.
To install the CLI run:

    npm install -g @litexa/core

From then on, you should be able to invoke the `litexa` command from anywhere on your machine.

::: warning Windows Users
Many of the examples in this guide are shown in a unix-style terminal. If there are any significant
differences between operating systems we'll call them out.
:::

## A Litexa project

### Generation

Once you've installed the Litexa CLI you can create a new Litexa project by opening up a terminal, navigating to
a directory where you have rights to create files, and typing:

    litexa generate

At this point you'll get a series of questions to help you get started. For now, answer the questions with the following
options:

<pre style="padding:0">
  <code>
    <span style="color:green">?</span> In which directory would you like to generate your project? <span style="color:#00caff">hello-litexa</span>
    <span style="color:green">?</span> Which language do you want to write your code in? <span style="color:#00caff">JavaScript</span>
    <span style="color:green">?</span> How would you like to organize your code? <span style="color:#00caff">Inlined in litexa</span>
    <span style="color:green">?</span> what would you like to name the project? <span style="color:#00caff">hello-litexa</span>
    <span style="color:green">?</span> what would you like the skill store title of the project to be? <span style="color:#00caff">hello-litexa</span>
  </code>
</pre>

This one command will create a new directory called `hello-litexa` and set up a simple Litexa project inside of it.
It will also print out the file names of the files it generated to the console.

### Structure

Let's review in a little more depth what files were generated and what our application looks like.

    cd hello-litexa

If we take a look at the contents of the directory we notice they look something like this

	.
	├── README.md
	├── artifacts.json
	├── litexa
	│   ├── assets
	│   │   ├── icon-108.png
	│   │   └── icon-512.png
	│   ├── main.litexa
	│   ├── main.test.litexa
	│   ├── utils.js
	│   └── utils.test.js
	├── litexa.config.js
	└── skill.js

::: tip Documentation
The **README.md** is a great place to start after generating a project. It provides information specific to the type of project
you've generated, and also includes a succinct synopsis of the contents covered in this getting started guide.
:::

This directory contains an number of auto-generated files and folders that make up the structure of a basic
litexa project. Here's a short rundown of each of the files and folders created by default:

* `README.md` contains useful tidbits of knowledge pertaining to your generated project.
* `artifacts.json` file stores generated information about the project.
* `litexa.config.js` is your project configuration file.
* `skill.js` is a representation of your skill that provides required metadata to Alexa.
* `litexa` folder houses your assets, litexa files, and skill logic:
    * `assets` contains any images, videos and sounds you'd like to deploy with your project.
    * `*.litexa` files are the Litexa language files.
    * `*.js` files are code files. Anything defined in them will be visible in the litexa global scope.

::: warning Importing Code
As mentioned above, code files inside of the `litexa` directory are treated differently.

For example, variable declarations and function definitions in a JavaScript file will be globally scoped. **This means
`require` and `import` have limited support in this context**. If you wish to organize your code in a way that you can
import/require your own files, you can run `litexa generate` and select the `As modules.` or `As an application.` option.

For more information on this and for generation shorthands, check out the [Project Structure](../book/project-structure.md)
section of the cookbook.
:::

### The Code
*If you want to go straight to getting your skill up and running, feel free to skip this section.
This part just skims through the content of your generated skill code.*

<details><summary>Click to show the Litexa code walkthrough</summary>

Before we run our code, lets take a look at the contents of our code files in the `litexa` folder.

::: tip Syntax Highlighting
If you want to be able to better read the code samples, we provide a Visual Studio Code extension to support Litexa syntax
highlighting. You can find it under the folder `packages/litexa-vscode` in the Litexa codebase.

For other editors, we recommend extending your `coffeescript` syntax highlighting to include `*.litexa` files, as Litexa
language extensions don't exist for other editors yet.
:::

Open the `main.litexa` file and take a minute to look it over. In it, you should see the following sections
`launch`, `askForName`, `waitForName`, and `goodbye`, each with its own content.

These are the states of your skill, and the content in each of these states is the logic for
what your skill should do in each of these scenarios. You can consider your `*.litexa` files as a state
diagram comprised of these states.

It's not expected that you should be able to read and understand this immediately, but the file should give you a general
sense for what you expect your skill to do. Breaking it down from the viewpoint of Alexa, it should
read a little something like this:

@[code lang=coffeescript transclude={2-10}](@/packages/litexa/src/command-line/templates/common/litexa/main.litexa)

When I launch, if I know the user's name, I should say "Hello again" with their name. If I don't
know their name, I just say "Hi there, human". Either way, I move on to the `askForName` state.

@[code lang=coffeescript transclude={12-17}](@/packages/litexa/src/command-line/templates/common/litexa/main.litexa)

When I'm in `askForName`, I ask for their name and - if I need to reprompt them - I'll say "Please tell me your name?".
I also transition to the `waitForName` state.

@[code lang=coffeescript transclude={19-33}](@/packages/litexa/src/command-line/templates/common/litexa/main.litexa)

When I'm in the `waitForName` state, since there's nothing to do, I wait for input. When they reply with their name,
I'll save it and say that it's nice to meet them, and then transition to the `goodbye` state.

@[code lang=coffeescript transclude={35-40}](@/packages/litexa/src/command-line/templates/common/litexa/main.litexa)

Alternatively, when I'm in the `waitForName` state, if the user asked for help instead of giving me their name, I'll
rephrase my question for their name and again wait for input.

@[code lang=coffeescript transclude={42-46}](@/packages/litexa/src/command-line/templates/common/litexa/main.litexa)

And if I just plain didn't understand them, I'll say I didn't understand and go back to `askForName`, and follow that
state's steps again.

@[code lang=coffeescript transclude={48-51}](@/packages/litexa/src/command-line/templates/common/litexa/main.litexa)

When I am in the `goodbye` state, I say goodbye and end the skill.

Great! Now that we have a sense for what our application should do when we run it, we should have a way to simulate user
interaction with your skill and check what we expected to happen. Open the `main.test.litexa` file, and you'll find a
couple of scenarios we've described.

Litexa provides you with a quick way to verify and assert that your litexa code behaves the way you'd expect.
Again, it's not expected that you should be able to read this immediately, but the file should give you a general sense
for what you're checking for.

These test scenarios are written from the perspective of someone observing the interaction between the user and Alexa.
Let's take a look at the first one:

@[code lang=coffeescript transclude={1-6}](@/packages/litexa/src/command-line/templates/common/litexa/main.test.litexa)

When the user launchs the skill, Alexa ends up in the `waitForName` state. The user then says "my name is Dude". At this
point in the interaction, the test verifies that the skill stored the name "Dude". The user then ends the
skill session.

::: tip Testing
For more information on ensuring your code works properly, check out the cookbook section on [Testing](../book/testing.md).
:::

</details>

### Building and Running

You already have a functional Litexa project at this point. To compile and and execute your code, run

```bash
litexa test
```

This command will build and run your Litexa project against your Litexa tests.
You should see the following output:

```coffeescript
2019-3-12 18:03:05 running tests in /Users/You/Documents/Sandbox/template_generation/hello-litexa with no filter
test step 1/3 +0ms: happy path
test step 2/3 +73ms: asking for help
test step 3/3 +11ms: utils.test.js
test steps complete 3/3 87ms total

2019-3-12 18:03:08
✔ 3 tests run, all passed (87ms)

Testing in region en-US, language default out of ["default"]
✔ test: happy path
2.  ❢    LaunchRequest    @ 15:01:05
     ◖----------------◗ "Hi there, human. What's your name?" ... "Please tell me your name?"
4.  ❢   MY_NAME_IS_NAME  $name=Dude @ 15:02:10
     ◖----------------◗ "Nice to meet you, Dude. It's a fine Tuesday, isn't it? Bye now!" ... NO REPROMPT
  ◣  Voice session ended
8.  ❢    LaunchRequest    @ 15:03:15
     ◖----------------◗ "Hello again, Dude. Wait a minute... you could be someone else. What's your name?" ... "Please tell me your name?"
10.  ❢   MY_NAME_IS_NAME  $name=Rose @ 15:04:20
     ◖----------------◗ "Nice to meet you, Rose. It's a fine Tuesday, isn't it? Bye now!" ... NO REPROMPT
  ◣  Voice session ended


✔ test: asking for help
16.  ❢    LaunchRequest    @ 15:01:05
     ◖----------------◗ "Hi there, human. What's your name?" ... "Please tell me your name?"
18.  ❢  AMAZON.HelpIntent  @ 15:02:10
     ◖----------------◗ "Just tell me your name please. I'd like to know it." ... "Please? I'm really curious to know what your name is."
20.  ❢   MY_NAME_IS_NAME  $name=Jimbo @ 15:03:15
     ◖----------------◗ "Nice to meet you, Jimbo. It's a fine Tuesday, isn't it? Bye now!" ... NO REPROMPT
  ◣  Voice session ended


✔ utils.test.js, 1 tests passed
  ✔ utils.test.js 'stuff to work'
  c! the arguments are
  c! {"0":1,"1":2,"2":3}
  t! today is Tuesday

✔ 3 tests run, all passed (87ms)
```

Congrats! You've built, run, and tested your code and you know it's working.

::: tip Modifying the code
Try playing around with the output and the expectations, don't worry about breaking your code. You can always re-generate
another project. In fact, try and break your tests! What happens if you don't save the name?
:::

### Deploying

Now, you have a working project and are ready to share it
with the world. The next step is to hear it come out of your
own Alexa Device.

We will be using AWS for the deployment of your skill. You
do not need to be familiar with AWS, but if you
continue to use it in deploying Alexa Skills, it would be
valuable to learn more about the AWS services your skill
uses.

::: tip AWS is one of many options for deployment
AWS is not required to build skills for Alexa or to use
Litexa. The compiled output could be deployed in any Node.js
compatible environment, but you will be off the beaten path
and starting on a new adventure. 🗺️
:::

#### Deployment Prerequisites

Before you deploy your skill, you must have have done the following
(and we'd recommend setting these up in this order, too):

* [Create an Amazon Developer Account](https://developer.amazon.com/alexa-skills-kit)
* [Create an AWS Account](https://aws.amazon.com/)
* [Create a custom IAM Policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_create.html)
  derived from the template below:
  * You will need to replace `myAccountId` and
    `myBucketName` with your [AWS account
    ID](https://docs.aws.amazon.com/general/latest/gr/acct-identifiers.html)
    and desired [S3
    bucket](https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html)
    name, respectively, for it to be valid.
  * <details><summary>Click to show the custom policy template</summary>

    @[code lang=json](@/docs/book/litexa-iam-policy-template.json)
    </details>
* [Create an IAM User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
  with the above custom IAM policy attached
* [Install the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) and
  [configure it](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) with your
  above IAM User credentials.
* [Install the ASK CLI](https://developer.amazon.com/docs/smapi/quick-start-alexa-skills-kit-command-line-interface.html#install-initialize)
  and sign into your Amazon Developer Account, when prompted during `ask init`. You can choose "Skip" when prompted to select an AWS
  profile to attach (Litexa handles AWS deployment separately).

#### Installation

We've created an extension to help you deploy your skill. To install it, run

```bash
npm install -g @litexa/deploy-aws
```

#### Setup

Deploying requires some simple setup. In the Litexa configuration you must specify your deployment module, the `S3BucketName`
you want to deploy to, your `askProfile`, and your `awsProfile`. By default, Litexa configures your project to deploy with
the `@litexa/deploy-aws` module for the `development` environment and sets the other options to `null`.

@[code lang=javascript transclude={16-23}](@/packages/litexa/src/command-line/templates/common/javascript/litexa.config.js)

::: warning NOTE
If your `S3BucketName` doesn't exist we'll create it for you, given that you provided an S3 bucket name that does not yet exist.
Your `askProfile` needs to match one that you configured with `ask init`.
Your `awsProfile` needs to match one that you configured with `aws configure` and has the IAM Policy listed above.
:::

#### Deploy

To deploy, go to your Litexa project root folder and run

```bash
litexa deploy
```

That's it.

This one command will:

* Build your project
* Upload your project assets to your S3 Bucket (and create the specified bucket, if it doesn't exist)
* Infer your language models
* Create your skill in the ASK Developer Console
* Upload your skill manifest to the ASK Developer Console
* Upload each of your language models to the ASK Developer Console per language region you support
* Create your Lambda
* Bundle your project, zip it up, and push it to Lambda
* Create the DynamoDB table for your skill to save data to

Don't worry if this seems like a lot. You can learn about each of these components in depth later. But now you should be
able to invoke your skill.

Try it out. Invoke your skill on an Alexa device connected to your Alexa account. Just say

    Alexa, open Hello Litexa

::: tip Alexa Simulator
If you don't have an Alexa device you can also visit the [ASK Developer Console](https://developer.amazon.com/alexa/console/ask)
and try out your skill in the Alexa Simulator.
:::

## Learn More

There might be some questions you have after reading this guide around the Alexa-specific language.

* What is a language model?
* What is a skill manifest?
* How do I render screens?

Here are some links to help you gain knowledge and answer some of those questions:

* [ASK](https://developer.amazon.com/alexa-skills-kit/)
* [ASK Documentation](https://developer.amazon.com/docs/ask-overviews/build-skills-with-the-alexa-skills-kit.html)
* [Screens](../book/screens.md)
* Game Developer Resources
  * [ASK-Gaming](https://developer.amazon.com/alexa-skills-kit/gaming)
  * [GameOn](https://developer.amazon.com/docs/gameon/overview.html)
