# {name}

This README is a quick-start guide to help you create, run, and deploy this Litexa project.

## Build

* `cd litexa`
* `npm run clean`
* `npm run compile`

These commands install the npm dependencies and compile your code. To facilitate this
action, Litexa generates the utility functions `clean` and `compile` in your `package.json`.

*Tip*: `npm run compile:watch` compiles your code as you make edits and changes to it.

## Running / Development

* `npm run test:litexa`

This command will compile your code then bundle and run your Litexa project against your Litexa tests.

* `npm run test:litexa:watch`

This command will compile your code then bundle and run your Litexa project against your Litexa tests
as you make edits and changes to your code.

## Building and Deploying

* `npm install -g @litexa/deploy-aws`
* `litexa deploy`

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
