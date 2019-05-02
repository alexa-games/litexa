# {name}

This README is a quick-start guide to help you create, run, and deploy this Litexa project.

## Running / Development

* `litexa test`

This command will build and run your Litexa project against your Litexa tests

* `litexa test --watch`

This command will build and run your Litexa projects against your Litexa tests continually.

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
