# {name}

This README is a quick-start guide to help you create, run, and deploy this Litexa project.

## Build

* `cd lib`
* `npm run clean` -- installs npm packages
* `npm run compile`
* `cd ../litexa`
* `npm run clean` -- installs and links npm packages

To build and link your code, you enter the `lib` directory build it first, then 
enter the litexa directory and link it to your project. To facilitate this action, Litexa generates the utility 
functions `clean` and `compile` in your `package.json`.

*Tip*: You must recompile your `lib` code for changes to reflect in Litexa, but it's not necessary to re-link it each time.

## Running

* `litexa test`

This command will build and run your Litexa project against your Litexa tests.

* `litexa test --watch`

This command will build and run your Litexa projects against your Litexa tests as you make changes to your files.

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
