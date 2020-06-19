# Litexa

![Litexa Logo](./logo.png)

Litexa is an Alexa domain specific language, developed for long form multi-turn skills such as games.
Its parser and tooling is implemented in Node.js and it compiles into JavaScript that expects Node.js
as a runtime environment.

**Note:** *Due to a dependency not compatible with Node.js v12 in the @litexa/assets-wav package, the
recommended local runtime and default deployment runtime is Node.js v10. If you are not using this
package, you are welcome to upgrade both your local and runtime environment to Node.js v12. Refer to our
[deployment documentation](./docs/book/deployment.md#lambda-configuration-optional) for more configuration
details.*

Full documentation is available at <https://litexa.com>

**Disclaimer:**
*Litexa is an Alexa Labs community-supported project (alpha) from the Alexa Games team at Amazon. We (Alexa Games) have
used Litexa to develop and ship 20+ Alexa skills. Your feedback is welcome and we are happy to consider contributions.
Otherwise, you are free to use and modify this software as needed. As with all open-source packages, please use them in
accordance with the licenses assigned to each package. For official Alexa supported skill development tools, we
recommend using tools in the [Alexa Skills Kit](https://developer.amazon.com/en-US/alexa/alexa-skills-kit) like [Skill
Flow Builder](https://developer.amazon.com/blogs/alexa/post/83c61d4e-ab3f-443e-bf71-75b5354bdc9e/skill-flow-builder) and
the [ASK SDK](https://developer.amazon.com/docs/alexa-skills-kit-sdk-for-nodejs/overview.html). Thanks and enjoy!*

## Packages

The following packages are in this repo.

### @litexa/core

The compiler and common tooling for Litexa. Installing this globally installs the Litexa command
line tool.

### @litexa/deploy-aws

A deployment module that pushes a skill to AWS using the services: Lambda, DynamoDB, and S3. Click
to learn more about the [Litexa deployment module](./docs/book/deployment.md#litexa-deploy-aws).

### @litexa/apl

An extension that makes working with APL documents in your Litexa project more powerful with
shorthand for managing APL documents and common design patterns. Click to learn more about the
[APL extension](./docs/book/screens.md#apl-directives).

### litexa-vscode

VS Code extensions for the Litexa language that provides syntax highlighting for ```.litexa```
files. Click to learn more about the [VS Code extension](./docs/get-started/README.md#the-code).

### @litexa/assets-wav

A WAV/MP3 composer that can combine multiple overlapping samples into a single MP3 stream, and a
binding layer for use in Literate Alexa. Click to learn more about the
[WAV audio converter](./docs/book/appendix-wav-conversion.md).

## Developer Setup

While having split code-bases facilitates code-sharing, it comes at a cost of increased difficulty
in tracking and testing features across repositories. For this reason we've decided to organize this
codebase into a multi-package repository (or monorepo).

This monorepo uses [Lerna](https://github.com/lerna/lerna#readme) to manage all of its packages.

To get started, run ```npm install``` from the root directory of the repository. This will install
the dependencies and bootstrap Lerna. Lerna `bootstrap` and `link` are called during postinstall.
To learn more, check out the
[@learna/bootstrap documentation](https://github.com/lerna/lerna/tree/master/commands/bootstrap).

### Global install from local

During development, you should install any packages you plan on modifying from the local package.

 ```bash
 npm install -g ./packages/litexa
 ```

You can also install multiple packages at the same time:

```bash
npm install -g ./packages/litexa ./packages/litexa-apl ./packages/litexa-deploy-aws
```

### Cleaning

It's important to get your base project to a consistent state. A utility function `clean` has been
provided for you. It removes `node_modules` and re-installs them for you and the runs
`npx lerna clean` which goes through each managed package and removes its `node_modules`

For more information on Lerna's `clean` command, check out the
[@learna/clean documentation](https://github.com/lerna/lerna/tree/master/commands/clean#readme).

### Testing

#### Unit Tests

To test your package run

```bash
npx lerna run test --scope [package-your-developing]
```

for example, if you wanted to run test litexa and @litexa/deploy-aws you'd run

```bash
npx lerna run test --scope litexa @litexa/deploy-aws
```

to run all the tests, omit the scoped flag

```bash
npx lerna run test
```

#### Coverage

to run test coverage for your package(s) run

```bash
npx lerna run coverage --scoped [package-your-testing]
```

to run them all

```bash
npm run coverage:lerna
```

#### Integration Tests

Integration tests are handled outside of Lerna, by the unpublished `@litexa/integration-tests` package
in the `./tests` directory. If you're writing an integration test, add it there. Integration tests can
also be referred to for usage examples of various Litexa features.

#### Misc

**Note**: all `run` does is accept an argument that it's going to use to run the npm script in your
package so all `npx lerna run test` is doing is going through each package and running the `test`
script from your package.json, if the script doesn't exist for a package it skips it.

For more information on the `run` command
[check out the Lerna docs](https://github.com/lerna/lerna/tree/master/commands/run#readme).

### Build

To build the entire project run

```bash
npm run build
```

from the root of the project directory. This command will do the following

* Remove and perform a clean install of the lerna project
* Clean all the package dependencies
* Clean all the test dependencies
* Look at all the packages, find any common dev dependencies or new packages and surface them up as
shared dependencies in package.json
* Bootstrap and Hoist them for use with Lerna aka Bundle them
* And run the Coverage for the entire project

if this command succeeds, you should have fair confidence the code is in a good working state.

### Adding a new package

To add a new package edit the `lerna.json` file with your new package run

```bash
npm run sync:dependencies
```

this will run the lerna `link` command and bring in the new package as a dependency for the lerna
project, as well as bring up the common devDependencies. After this is done, don't forget to run
`npm run clean` to install those dependencies, and version your changes.

For more information on the `link` command
[check out the lerna docs](https://github.com/lerna/lerna/tree/master/commands/link#readme)

## Documentation Website

Full documentation is available at <https://litexa.com.> To run the documentation
website locally, please do the following.

### One Time Setup

```bash
npm install -g vuepress
npm install -g markdown-it-vuepress-code-snippet-enhanced
```

### Generate Language Reference

In the `./packages/litexa/src/parser/litexa.pegjs` file all the comments can include markdown. From
the root to extract and update the website run

```bash
npm run docs:reference
```

### Run the Website

To start the docs website in interactive/watch mode, then run this:

```bash
npm run docs:dev
```

To run both the reference and the interactive site, run.

```bash
npm run docs
```

The website will update with any change in the docs folder.
For more info on Vuepress - <https://v0.vuepress.vuejs.org/guide/#how-it-works>

We are using a small extension to grab code from docs. Info here:
<https://www.npmjs.com/package/markdown-it-vuepress-code-snippet-enhanced>

### Build The Website for Hosting

To build the full static website for S3 or GitHub hosting, run the following:

```bash
npm run docs:build
```

## Security

Security is of the utmost importance. This section will describe NPM scripts that
can help with making sure that the code base is as secure as possible.

### Dependency Audit

NPM provides a tool that will scan and automatically install any compatible updates
to vulnerable dependencies. More on `npm audit` [here](https://docs.npmjs.com/cli/audit).

To run the tool against every Litexa package, run the following from
the root of the code base:

```bash
npm run audit:fix
```

If the tool does automatically install any compatible updates, it's advised to run
`npm run coverage` before you commit any changes (to make sure nothing has broken in
the update).
