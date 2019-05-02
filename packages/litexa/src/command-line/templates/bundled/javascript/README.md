# {name}

This README is a quick-start guide to help you create, run, and deploy a Litexa project.

## Build

* `npm run clean`
* `npm run compile`

These commands install the npm dependencies and compile your code. The compilation process will bundle your
code into a single executable `main.min.js` and place it in the `litexa` folder. To facilitate this action, Litexa
generates the utility functions `clean` and `compile` in your `package.json`.

*Tip*: `npm run compile:watch` compiles your code as you make edits and changes to it.

## Running / Development

* `npm test`

This command will run the spec files in your `test` folder.

* `npm run test:watch`

This command will run the spec files in your `test` folder as you make edits and changes to your code.

* `npm run test:litexa`

This command will compile, bundle, then run your Litexa project against your Litexa tests.

* `npm run test:litexa:watch`

This command will compile, bundle, then run your Litexa project against your Litexa tests
as you make edits and changes to your code.

## Building and Deploying

* `npm install -g @litexa/deploy-aws`
* `npm run deploy` -- compiles your code and calls `litexa deploy`

To deploy your code you must specify the deployment module in your Litexa configuration. By default, Litexa
configures your project to deploy with the `@litexa/deploy-aws` module for the `development` environment.

## Command Reference

* `litexa --help`
* `litexa <command> --help`

`--help` provides more information when used in conjunction with a command, e.g. `litexa generate --help`. When used
on its own, it provides general information about the Litexa CLI.

## Further Reading / Useful Links

* [ASK](https://developer.amazon.com/alexa-skills-kit/)
* [ASK Documentation](https://developer.amazon.com/docs/ask-overviews/build-skills-with-the-alexa-skills-kit.html)
* Game Developer Resources
  * [ASK-Gaming](https://developer.amazon.com/alexa-skills-kit/gaming)
  * [GameOn](https://developer.amazon.com/docs/gameon/overview.html)
