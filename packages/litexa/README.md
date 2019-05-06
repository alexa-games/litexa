# Litexa Package

Litexa is an Alexa domain specific language, developed for long form multi-turn skills such as games.
This package contains the source for the CLI and core runtime.

Further documentation can be found at <https://litexa.github.io>

## Installing Litexa

### Prerequisites

The following needs to be installed and configured:

* [Node.js](https://nodejs.org/) (with npm)

Note: Requires Node.js version 8.11 or higher.

### Installing

Litexa is intended to be used as a command line
utility, installed as a global npm package.
Given an environment with node installed:

```bash
npm install -g @litexa/core
```

From then on, you should be able to invoke the `litexa`
command from anywhere on your machine.

Note: if you are installing from the source monorepo, then you
can use a local reference for installing instead. Switch to
the litexa directory, then run:

    npm install ./ -g

Additional components of Litexa are provided as
separate extension modules, with the intention that each
project can pick and choose which functionality it would
like to incorporate. See further below for a list of known
extensions.
