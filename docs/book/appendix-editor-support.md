# Appendix: Editor Support

We have written a Visual Studio Code (VS Code) plugin that supports syntax highlighting for files written in the Litexa
language for Alexa skills. Any such files will be denoted with the `.litexa` file extension.

## Installation

To install this extension, you will need to have cloned the [alexa-games/litexa](https://github.com/alexa-games/litexa)
repository. From the `packages` directory, you can either copy or symlink the `litexa-vscode/litexa` directory to your
[VS Code extensions directory](#vs-code-extensions-directory) and relaunch VS Code.

::: tip Symlinking
The added benefit of using a symlink is being able to keep the extension up-to-date by running `git pull` on this project when a
new feature is launched.
:::

### VS Code Extensions Directory
Extensions are installed in a per-user extensions directory. Depending on your platform, the directory is located here:

* Windows `%USERPROFILE%\.vscode\extensions`
* macOS `~/.vscode/extensions`
* Linux `~/.vscode/extensions`

You can change the location by launching VS Code with the `--extensions-dir <dir>` command line option.

## Resources

* [Installing your VS Code Extensions Locally](https://vscode-docs.readthedocs.io/en/stable/extensions/example-hello-world/#installing-your-extension-locally)
* [Your VS Code Extensions Folder](https://vscode-docs.readthedocs.io/en/stable/extensions/install-extension/#your-extensions-folder)
