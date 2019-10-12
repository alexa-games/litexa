---
home: true
tagline: A new <a href="https://en.wikipedia.org/wiki/Literate_programming">literate style programming</a> language and toolchain for building long form Alexa skills
heroText: Litexa
actionText: Get Started →
actionLink: /get-started/
pageClass: cloudy-home
features:
  - title: The Language
    details: Purpose built for writing Alexa skills, succinct syntax gives you language level support for defining state machines that turn incoming voice requests into rich responses. Built-in statements handle composing SSML speech, displaying screens, creating directives, and adding variations to your flow and delivery.
    button:
      text: Read the full Language Specification
      link: /book/

minorFeatures:
  - title: The Compiler
    img: /icons/compiler_160x96.png
    details: Emits standard, highly performant JavaScript code ready to deploy to a host like AWS Lambda. Compile time checking of things like language model elements and asset references means fewer bugs to discover at runtime.
  - title: The Toolchain
    img: /icons/toolchain_160x96.png
    details: A one-step build and deploy system that seamlessly synchronizes your language model and deploys your skill endpoint, assets, and storage to AWS.
  - title: Extensions
    img: /icons/extensions_160x96.png
    details: Designed to be tweaked, Litexa extensions let you add new features to the compiler and toolchain, even add new syntax. Build tools to dig into what makes your team and project special.
secondaryFeatures:
  - title: State Management
    details: Litexa's syntax is designed around the central idea of handling incoming intents based on the user's current state.
    button:
      text: Learn more about State Management
      link: /book/state-management.html
  - title: Screen Devices
    details: For Alexa-enabled devices with a screen, Litexa supports easily building, sending, and validating both Alexa Presentation Language (APL) and <code>Display.RenderTemplate</code> directives.
    button:
      text: Read the Screens documentation
      link: /book/screens.html
  - title: Variables &amp; JS Interpolation
    details: "Litexa variables can be easily persisted and retrieved between skill launches, and resolved request slot values are handled seamlessly. Additionally, JavaScript interpolation is effortless: JS values (including objects, arrays, and functions) can be directly accessed from within Litexa."
    button:
      text: Read the Variables and Expressions documentation
      link: /book/expressions.html
faqs:
  - question: How much does Litexa cost? Where does it come from?
    answer: Litexa is <em>free!</em>&nbsp; Litexa is an Alexa Labs community-supported project (alpha) from the Alexa Games team at Amazon. We (Alexa Games) have used Litexa to develop and ship 20+ Alexa skills. Your feedback is welcome and we are happy to consider contributions. Otherwise, you are free to use and modify this software as needed. As with all open-source packages, please use them in accordance with the licenses assigned to each package. For official Alexa supported skill development tools, we recommend using tools in the <a href='https://developer.amazon.com/en-US/alexa/alexa-skills-kit/'>Alexa Skills Kit</a> like <a href='https://developer.amazon.com/blogs/alexa/post/83c61d4e-ab3f-443e-bf71-75b5354bdc9e/skill-flow-builder'>Skill Flow Builder</a> and the <a href='https://developer.amazon.com/docs/alexa-skills-kit-sdk-for-nodejs/overview.html'>ASK SDK</a>.
  - question: Does Litexa handle Alexa feature X?
    answer:  Check out <a href='book/'>the documentation book</a> for features that Litexa has value added syntax for. Don't see something you want to use? No sweat, Litexa lets you write your own directives from scratch, and whitelist incoming event names.
  - question: Can I still use my JavaScript libraries?
    answer: Yes! Litexa compiles into a JavaScript closure that you can inject code into, in order to add symbols that will be visible to your Litexa code. In there you can refer to any external modules in the usual way, and thereby pass their symbols up to Litexa too.
  - question: I really like writing in TypeScript/CoffeeScript can I still do that?
    answer:  Hey, actually we do too! Beyond a certain level of complexity, it's nice to split up your presentation code from your business logic, and the Litexa/JavaScript boundary is a great fit for that. The <code>litexa generate</code> command has a series of options, including primary code language and bundling strategy, that will help you jump right in.
  - question: Why a language?
    answer: We just really care about syntax, and getting any boilerplate out of the way so that we're as close as we can be to just iterating on content.
  - question: Can I make any kind of Alexa skill with Litexa?
    answer: You know, we've mostly made games with it, so we can't say for sure. We'd very much love to hear about your experiences if you try something else though. Feel free to submit a pull request if you need something to change!
  - question: What extensions and features are currently available?
    answer: <ul><li><strong>litexa/deploy-aws:</strong> A deployment module that pushes a skill to AWS using Lambda, DynamoDB, and S3.</li><li><strong>litexa/apl:</strong> An extension that makes working with the Alexa Presentation Language (APL) in your Litexa project more powerful, with shorthand for managing APL documents and common design patterns.</li><li><strong>litexa/render-template:</strong> An extension that supports easily building, sending, and validating a <code>Display.RenderTemplate</code> directive, the predecessor to APL.</li><li><strong>litexa/assets-wav:</strong> A WAV/MP3 composer that can combine multiple overlapping samples into a single MP3 stream, and a binding layer for use in Literate Alexa.</li><li><strong>litexa/gadgets:</strong> An extension for the Gadgets Skill API, which powers interaction with Echo Buttons (and potentially other Alexa Gadgets).</li></ul> Additionally, there is built-in support for <a href='book/monetization.html'>In Skill Purchasing (ISP)</a> in the core package, and a <a href='#'>VSCode extension</a> that provides syntax highlighting for <code>.litexa</code> files. We've also provided documentation for how to <a href='book/backdoor.html'>use Alexa features that Litexa does not yet support</a>.

footer: >
    Brought to you with ❤ by the Alexa Games team at Amazon.
    © 2019, Amazon.com, Inc. or its affiliates. All Rights Reserved.
---

## Install, Generate, Test, and Deploy

```bash
# install
npm install -g @litexa/core
npm install -g @litexa/deploy-aws

# generate a skill
mkdir mySkill
cd mySkill
litexa generate

# test your skill locally
litexa test

# deploy to aws
litexa deploy
```
