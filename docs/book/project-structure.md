# Project Structure

Litexa provides you with three different strategies to organize your code, each of which has a specific philosophy
behind it:

1. **Inlined** ... ideal for smaller projects with limited dependencies
2. **Separate** ... ideal for medium-sized, modular projects
3. **Bundled** ... ideal for compressing large, multi-layered projects

In order to help you select the strategy that's right for you, we'll approach the problem pragmatically by looking at it
through the lens of an Alexa skill. Assume you've been tasked with building the following trivia skill:

::: tip Gameplay

* Player launches the game, upon which Alexa reads the rules.
* The game consists of 3 rounds of at most 10 clues each.
* In a round, each consecutive clue becomes increasingly easier.
* The more clues it takes before the player answers correctly, the fewer points the player receives. For instance:
  * correct answer after first clue: 10 points
  * correct answer after tenth clue: 1 point
* After all 3 rounds, Alexa announces the player's score and exits.
:::

Below we'll take a look at each strategy in turn, and discuss when it might be meaningful for you to use that strategy
for the above skill's development.

## Inlined

Let's assume you want to quickly prototype and iterate your trivia skill to answer questions such as:

* Is the game's concept viable?
* What can I do to make the game fun?
* What wording sounds good for Alexa's prompts?
* How long should Alexa wait between clues?
* Should there be silence or audio between clues?

This would be a scenario where choosing the inlined project structure is meaningful.

::: tip Use Inlined when:

* rapid prototyping and iteration are desired
* few or no external dependencies are required
* there is no need to `import`/`require` self-authored files
* project size is small
:::

### Generation

The decision to pick a project structure happens when you `litexa generate` a project. There are two ways to generate
a project with an inlined structure.

1. You can use generation flags like this:

    ```bash
    litexa generate quiz-trivia-inlined --bundling-strategy none
    ```

    ::: warning Defaults
    If you use flags, you will not be prompted about which language to use for your configuration files
    (i.e. `litexa.*` and `skill.*` in project root) or your source code: They will default to JavaScript.
    To specify these options you can pass them as flag options to the `generate` command.

    Your options are as follows:

    ```stdout
    -c, --config-language   [configLanguage]    language of the generated configuration file, can be javascript, json, typescript, or coffee
    -s, --source-language   [sourceLanguage]    language of the generated source code, can be javascript, typescript, or coffee
    -b, --bundling-strategy [bundlingStrategy]  the structure of the code layout as it pertains to litexa, can be webpack, npm-link, or none
    ```

    To see your generation options you can run `litexa generate --help`.
    :::

2. or, if you aren't using flags:

    ```bash
    litexa generate quiz-trivia-inlined
    ```

    and select the following answer when prompted:

    <pre style="padding:0"><code>
      <span style="color:green">?</span> How would you like to organize your code? <span style="color:#00caff">Inlined in litexa</span>
    </code></pre>

::: tip NOTE
If you prefer, `litexa init` is available as an equivalent to `litexa generate`.
:::

### Structure

An inlined project would look something like this:

```stdout
.
├── README.md
├── artifacts.json
├── litexa
│   ├── assets
│   │   ├── icon-108.png
│   │   └── icon-512.png
│   ├── main.litexa
│   ├── main.test.litexa
│   └── utils.js
├── litexa.js
├── node_modules
├── package-lock.json
├── package.json
└── skill.js
```

Here's a full breakdown of all the files and directories you could have in an inlined Litexa project:

* `litexa.(json|js|ts|coffee)` file is the Litexa configuration. A Litexa project is any directory with a valid Litexa
configuration file.
* `skill.(json|js|ts|coffee)` file contains a subset of the information found in an
[Alexa skill manifest](https://developer.amazon.com/docs/smapi/skill-manifest.html). Placeholders within (e.g. skill
summary and description) should be replaced according to the skill's usage.
* `artifacts.json` file captures information about the project, such as the skill ID for each deployment or the
ARN of lambdas (and the Git commit hash, when using Git). Please refer to the
[artifacts.json guidelines](#artifacts-json) for information on sharing this file.
* `tsconfig.json` and `tslint.json` files exist if you use TypeScript to configure your project. They contain your
project configuration's compilation and linting settings.
* `package.json` is a standard npm file and is necessary when you have npm packages you would like to depend on but that
will not be shipped with the skill (such as build tools and compile-time extensions).
* `package-lock.json` is the standard npm lock file that is responsible for deterministic installation of your project
dependencies.
* `node_modules` contains all of the packages you installed with npm as specified in the package.json file. These
packages will NOT be deployed with your skill.
* `README.md` file contains information about your generated project's structure.

* `litexa` directory contains your assets, Litexa files, and skill logic:
  * `*.litexa` files are the Litexa language files.
  * `*.(js|ts|coffee)` files are code files. Any functions or variables you define here are visible within the states
  defined in your `.litexa` files.
  * `assets` contains any images, videos and sounds you'd like to deploy with your project.
  * `languages` contains a directory per additional language you'd like to support, beyond your default language (see
  [Localization](localization.md) for more details).
  * `package.json` is a standard npm file and is necessary when you have npm packages you would like to depend
  on at runtime.
  * `package-lock.json` is the standard npm lock file that is responsible for deterministic installation of your project
  dependencies.
  * `node_modules` contains all of the packages you installed with npm as specified in the package.json file. These
  packages WILL be deployed along with your handler.
  * `tsconfig.json` and `tslint.json` files will exist if you chose TypeScript as the source code language for your
  project. They will contain your project code's compilation and linting settings.

### Up and Running

The generated project should now be ready for use as-is (unless you're using TypeScript - see additional steps
below), meaning you should now be able to run `litexa test` and `litexa deploy`!

:::warning Additional TypeScript Setup

* If you chose TypeScript as the language for your *configuration* files you need to run the following commands from
your project's root directory.
* If you chose TypeScript as the language for your *source code* files, you need to run the following
commands from within your project's `litexa` directory.

```bash
npm install
npm run compile
```

Note, that the following utility scripts will also compile your configuration files, when run from your project's
root directory (assuming you've run `npm install`):

```bash
npm run test
npm run deploy
```

:::

### Using external packages

If you want to add external runtime dependencies that you want to ship with your Litexa project, you can do so using
npm. Inside your project's `litexa` directory, run:

```bash
npm init
```

Answer the prompts which will create a `package.json` file in your `litexa` directory. Then, save any runtime
dependencies you require, by running:

```bash
npm install --save [your dependency]
```

You can then require the external packages from any of your inline code files and use them in the Litexa scope.
On deployment, the entire contents of `litexa/node_modules` will be deployed alongside your skill handler.

To add tools for use during the development of your skill, you can also create a `package.json` file in your project's
root directory and install dependent modules in the same way. These should not be runtime dependencies, since they
won't deploy with your code.

::: tip Extensions
Some Litexa extension packages with runtime functionality are designed to be installed at the project's root
directory since their runtime code will be inlined in the handler.

When installing a Litexa extension, consult its README for installation instructions.
:::

::: warning Require/Import

Only `require`/`import` packages that are added as dependencies in `litexa/package.json`. **Do not** use an inlined
project structure if you need to `require`/`import` any self-authored files. Doing so will fail, since variable
declarations and function definitions in your code files will be globally scoped.

To `require`/`import` your self-authored code, use the [Separate](#separate) or [Bundled](#bundled) project structure.
:::

## Separate

Using the above trivia skill example, let's assume you already have a solid idea of what the product is going to look
like, but realize your skill might have more complex requirements, since you'd like to:

* author and require some elaborate logic (e.g. to gather metrics) at runtime
* collaborate with friends on creating the skill
* divide the code into distinct areas of concern

In this scenario, the separate project structure might be the most meaningful.

::: tip Use Separate when:

* it's necessary to `require`/`import` self-authored files
* multiple developers might be collaborating on different divisions of code
* project size is medium
:::

### Generation

There are two ways to generate a project with a separate structure.

1. You can use generation flags like this:

    ```bash
    litexa generate quiz-trivia-separate --bundling-strategy npm-link
    ```

2. or, if you aren't using flags:

    ```bash
    litexa generate quiz-trivia-separate
    ```

    and select the following answer when prompted:

    <pre style="padding:0"><code>
      <span style="color:green">?</span> How would you like to organize your code? <span style="color:#00caff">As modules.</span>
    </code></pre>

### Structure

A separate project would look something like this:

```stdout
.
├── README.md
├── artifacts.json
├── lib
│   ├── index.js
│   ├── logger.js
│   ├── mocha.opts
│   ├── package.json
│   ├── utils.js
│   └── utils.spec.js
├── litexa
│   ├── assets
│   │   ├── icon-108.png
│   │   └── icon-512.png
│   ├── main.js
│   ├── main.litexa
│   ├── main.test.litexa
│   └── package.json
├── litexa.js
└── skill.js
```

Here's a full breakdown of all the files and directories you could have in a separate Litexa project:

* `litexa.(json|js|ts|coffee)` file is the Litexa configuration. A Litexa project is any directory with a valid Litexa
configuration file.
* `skill.(json|js|ts|coffee)` file contains a subset of the information found in an
[Alexa skill manifest](https://developer.amazon.com/docs/smapi/skill-manifest.html). Placeholders within (e.g. skill
summary and description) should be replaced according to the skill's usage.
* `artifacts.json` file captures information about the project, such as the skill ID for each deployment or the
ARN of lambdas (and the Git commit hash, when using Git). Please refer to the
[artifacts.json guidelines](#artifacts-json) for information on sharing this file.
* `tsconfig.json` and `tslint.json` files exist if you use TypeScript to configure your project. They contain your project
configuration's compilation and linting settings.
* `package.json` is a standard npm file and is necessary when you have npm packages you would like to depend on but that
will not be shipped with the skill. Typically these are build tools and compile-time extensions.
* `package-lock.json` is the standard npm lock file that is responsible for deterministic installation of your project
dependencies.
* `node_modules` contains all of the packages you installed with npm as specified in the package.json file. These
packages will NOT be deployed with your skill.
* `README.md` file contains information about your generated project's structure.

* `lib` directory contains a locally managed npm package. The directory name is arbitrary and you can add analogous
directories, as needed. The directory contains:
  * `package.json` is a standard npm file and is necessary to recognize this directory as an npm package. You should
  set the entry-point and package name within.
  * `*.(js|ts|coffee)` files are your code files.
  * `*.spec.(js|ts|coffee)` files are Mocha tests files for your code.
  * `mocha.opts` is the configuration file for Mocha.

* `litexa` directory contains your assets, Litexa files, and skill logic:
  * `*.litexa` files are the Litexa language files.
  * `*.(js|ts|coffee)` files are code files. Any functions or variables you define here are visible within the states
  defined in your `.litexa` files.
  * `assets` contains any images, videos and sounds you'd like to deploy with your project.
  * `languages` contains a directory per additional language you'd like to support, beyond your default language (see
  [Localization](localization.md) for more details).
  * `package.json` is a standard npm file and is necessary when you have npm packages you would like to depend
  on and deploy with your skill.
  * `package-lock.json` is the standard npm lock file that is responsible for deterministic installation of your project
  dependencies.
  * `node_modules` contains all of the packages you installed with npm as specified in the package.json file. These
  packages WILL be deployed as a copy along with your handler.
  * `tsconfig.json` and `tslint.json` files will exist if you chose TypeScript as the source-code language for your
  project. They will contain your project code's compilation and linting settings.

::: tip NOTE
The `lib` directory is a separately managed dependency. Thus, you are free to structure your code in any way you see fit
as long as it is a valid npm package that npm can install in the `litexa` directory. You can also extend and replicate
this pattern by creating new top level directories that are local npm packages, and importing those in the `litexa`
directory's package.

Further details on using local Node packages can be found here:
[NPM Local Paths](https://docs.npmjs.com/files/package.json#local-paths)
:::

### Up and Running

At minimum, you need to run `npm install` from your `litexa` directory (this will install any external directories
you've required, such as `lib` by default).

Unless you're using TypeScript (see additional steps below), you should then be able to run `litexa test` and
`litexa deploy`!

:::warning Additional TypeScript Setup

* If you chose TypeScript as the language for your *configuration* files you need to run the following commands from
your project's root directory.
* If you chose TypeScript as the language for your *source code* files, you need to run the following
commands from within your project's `lib` directory.

```bash
npm install
npm run compile
```

Note, that the following utility scripts will also compile your configuration files, when run from your project's
root directory (assuming you've run `npm install`):

```bash
npm run test
npm run deploy
```

Finally, to link your now compiled TypeScript packages to your Litexa project, run the following in the `litexa`
directory:

```bash
npm install
```

:::

### Using external packages

If you want to add external runtime dependencies that should be deployed with your Litexa project code, you can install
them

* in one of your locally required package directories (e.g. `lib`), or
* directly in the `litexa` directory

by running:

```bash
npm install --save [your dependency]
```

::: tip Dev Dependencies
In your locally managed packages, be sure to save any packages you do not want deployed for availability during runtime
as `devDependencies`. This is done by using the flag `--save-dev` instead of `--save`.

Importantly, this avoids unnecessarily bloating the size of your deployed skill.

:::

## Bundled

Again using the above trivia skill example, let's assume you know exactly what your product will look like. In addition
to the `separate` strategy conditions, you realize you might need:

* code layering (e.g. if you wanted to communicate with your own trivia server via a network layer)
* increased project size due to growing game logic and/or content

In this scenario, the bundled project structure might be the most meaningful. This approach will create a single,
compressed executable (bundled with any package dependencies).

::: tip Use Bundled when:

* it's necessary to `require`/`import` self-authored files
* multiple developers might be collaborating on the skill
* code architecture requires layering (e.g. separate layers for business logic and presentation)
* project size is large
:::

### Generation

There are two ways to generate a project with a bundled structure.

1. You can use generation flags like this:

    ```bash
    litexa generate quiz-trivia-bundled --bundling-strategy webpack
    ```

2. or, if you aren't using flags:

    ```bash
    litexa generate quiz-trivia-bundled
    ```

    and select the following answer when prompted

    <pre style="padding:0"><code>
      <span style="color:green">?</span> How would you like to organize your code? <span style="color:#00caff">As an application.</span>
    </code></pre>

### Structure

A bundled project would look something like this:

```stdout
.
├── README.md
├── artifacts.json
├── lib
│   ├── components
│   │   ├── logger.js
│   │   └── utils.js
│   ├── index.js
│   └── services
│       └── time.service.js
├── litexa
│   ├── assets
│   │   ├── icon-108.png
│   │   └── icon-512.png
│   ├── main.litexa
│   └── main.test.litexa
├── litexa.js
├── mocha.opts
├── package-lock.json
├── package.json
├── skill.js
├── test
│   ├── components
│   │   └── utils.spec.js
│   └── services
│       └── time.service.spec.js
└── webpack.config.js
```

:::tip Quick Overview

Alongside creating the configuration files in your project's root directory, this strategy generates the following
three top level directories:

1. `litexa` directory
2. `lib` directory with a hierarchy intended to help organize your code (components, services, etc.)
3. `test` directory that mirrors the hierarchy found in `lib`, and should contain any tests
:::

Here's a full breakdown of all the files and directories you could have in a bundled Litexa project:

* `litexa.(json|js|ts|coffee)` file is the Litexa configuration. A Litexa project is any directory with a valid Litexa
configuration file.
* `skill.(json|js|ts|coffee)` file contains a subset of the information found in an
[Alexa skill manifest](https://developer.amazon.com/docs/smapi/skill-manifest.html). Placeholders within (e.g. skill
summary and description) should be replaced according to the skill's usage.
* `artifacts.json` file captures information about the project, such as the skill ID for each deployment or the
ARN of lambdas (and the Git commit hash, when using Git). Please refer to the
[artifacts.json guidelines](#artifacts-json) for information on sharing this file.
* `tsconfig.json` and `tslint.json` files exist if you use TypeScript to configure your project. They contain your
project configuration's compilation  and linting settings.
* `package.json` is a standard npm file and is necessary when you have npm packages you would like to depend on but that
will not be shipped with the skill. Typically these are build tools and compile-time extensions.
* `package-lock.json` is the standard npm lock file that is responsible for deterministic installation of your project
dependencies.
* `mocha.opts` is the opts file for mocha.
* `node_modules` contains all of the packages you installed with npm as specified in the package.json file. These
packages will NOT be deployed with your skill.
* `README.md` file contains information about your generated project's structure.
* `lib` directory contains an `index.(js|ts|coffee)` file, which is the webpack entry-point for your application.
Whatever you export in this file will be visible and accessible in Litexa (via the compiled `main.min.js`).
Additionally, it should contain all of your skill's non-Litexa code, and can be divided into layers:
  * `components` directory could contain your code components (comes with simple logger/utils examples, to get
  you started).
  * `services` directory could contain your service code (comes with a simple time.service example, to get you started).
  * `data` directory could contain any data access layer code.
  * `*.(js|ts|coffee)` files are your code files.

* `test` directory mirrors `lib` and contains tests for each of your files.
  * `*.spec.(js|ts|coffee)` Mocha tests files for your code.

* `litexa` directory contains your assets, Litexa files, and skill logic:
  * `*.litexa` files are the Litexa language files.
  * `*.(js|ts|coffee)` files are code files. Any functions or variables you define here are visible within the states
  defined in your `.litexa` files.
  * `assets` contains any images, videos and sounds you'd like to deploy with your project.
  * `languages` contains a directory per additional language you'd like to support, beyond your default language (see
  [Localization](localization.md) for more details).
  * `tsconfig.json` and `tslint.json` files will exist if you chose TypeScript as the source-code language for your
  project. They will contain your project code's compilation and linting settings.

### Up and Running

First, you will need to run `npm install` from your project's root directory, to install any dependencies.

You will then need to compile your code (this will generate the `main.min.js` bundle that exposes your code to the
Litexa context). To do so, you can either explicitly `npm run compile`, or implicitly compile your code using the
utility scripts for testing/deploying your project:

```bash
npm run test:litexa
npm run deploy
```

::: tip Utility Scripts
Check the additional *scripts* in `package.json` which have been provided to facilitate compiling, testing, deploying,
and linting your project.
:::

### Using External Packages

If you want to add external runtime dependencies that should be deployed with your Litexa project code, you can install
them in your project's root directory using `npm install --save [your dependency]`. If the dependency is only needed
for development (and not required at runtime), use `--save-dev` instead of `--save`.

### Testing

The bundled strategy comes pre-configured with the generated tests to work with Mocha, Chai, and Sinon, to help you
get started. The Mocha configuration file (`mocha.opts`) can be found in your project's root directory, and the
testing scripts can be found in `package.json` (prefixed with *test*).

If you already have a preferred testing stack, please modify this setup to suit your needs.

## Guidelines

### artifacts.json

As seen above, each of the 3 strategies' project structure contains an `artifacts.json` file with certain skill
information (similar to the traditional `.ask/config`). This file is relevant for anybody collaborating on the skill,
and should be shared accordingly.

:::danger
If you use the [`@litexa/deploy-aws`](deployment.html#litexa-deploy-aws) extension to deploy your skill,
`artifacts.json` will also contain sensitive information such as the skill's AWS configuration, and should therefore
not be shared publicly. Make sure to use a private repository or other means of sharing the file, if you plan on
distributing your skill project publicly.
:::

### Credential Management

Because Litexa requires a developer account for deployment, we recommend reviewing the documentation for
[Developer Account Management](https://developer.amazon.com/docs/app-submission/manage-account-and-permissions.html)
and, if you are working in a team,
[Team Account Best Practices](https://developer.amazon.com/docs/smapi/ask-cli-intro.html#team-account-management-best-practice).

:::tip AWS Credentials
If you are using [`@litexa/deploy-aws`](deployment.html#litexa-deploy-aws) for deployment, please also review:
* [AWS Security Credentials](https://docs.aws.amazon.com/general/latest/gr/aws-security-credentials.html)
* [Best Practices for Managing AWS Access Keys](https://docs.aws.amazon.com/general/latest/gr/aws-access-keys-best-practices.html)
* [IAM User-specific Credential Management](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)
:::
