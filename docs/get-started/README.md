
# Preamble

This guide covers how to get up and running with Litexa.

After reading this guide you'll know:

<span style="color:#00caff; font-family:Helvetica,sans-serif">&#10004;</span> How to generate a new Litexa project<br/>
<span style="color:#00caff;font-family:Helvetica,sans-serif">&#10004;</span> The anatomy of a Litexa project<br/>
<span style="color:#00caff;font-family:Helvetica,sans-serif">&#10004;</span> How to run, modify, and test your code<br/>
<span style="color:#00caff;font-family:Helvetica,sans-serif">&#10004;</span> How to deploy your code<br/>
<span style="color:#00caff;font-family:Helvetica,sans-serif">&#10004;</span> Where you can go to learn more about Litexa<br/>




## What is Litexa?

Litexa is both a framework and a language for writing Alexa skills. The framework lets you define, test, and deploy your
language model, your skill handler, and any associated assets. The language is a convenient domain-specific language (DSL)
that allows you to focus on the logic and presentation of your skill over utility code to interact with Alexa.

::: tip Wait, why do I need Node.js?
Litexa is a DSL that compiles down to performant and ES5 compliant JavaScript that runs on Node.js.

While you could write your skill solely in the Litexa language, it is not meant to be general purpose. In fact, you'll
often want to incorporate external code and dependencies alongside your skill logic in Litexa.
:::



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




## Installation

### Prerequisites

* Operating Systems: We know that the following operating
  systems work fine, but any OS that runs the supported
  version of Node.js is a candidate.
  * Mac OS - Sierra, High Sierra, Mojave
  * Windows 10 x64
  * Linux - Ubuntu (14, 16, 18)
* Environment
  * [Node.js](https://nodejs.org/) version <strong>10.x</strong> or higher

### Installation Steps

Litexa is a command line utility that is installed as a global npm package.
To install the CLI run:

```bash
npm install -g @litexa/core
```

From then on, you should be able to invoke the `litexa` command from anywhere on your machine.

::: warning Windows Users
Many of the examples in this guide are shown in a unix-style terminal. If there are any significant
differences between operating systems we'll call them out.
:::


