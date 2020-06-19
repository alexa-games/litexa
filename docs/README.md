---
home: true
tagline: A new <a href="https://en.wikipedia.org/wiki/Literate_programming">literate style programming</a> language and toolchain for building long form Alexa skills
heroText: Litexa
actionText: Get Started →
actionLink: /get-started/

footer: >
    Brought to you with ❤ by the Alexa Games team at Amazon.
    © 2019, Amazon.com, Inc. or its affiliates. All Rights Reserved.
---

<Feature title="The Language" link="/book/" link-text="Read the full Language Specification">
::: slot description
Purpose built for writing Alexa skills, succinct syntax gives you language level support for defining state machines that turn incoming voice requests into rich responses. Built-in statements handle composing SSML speech, displaying screens, creating directives, and adding variations to your flow and delivery.
:::

::: slot code
```coffeescript
launch
  say "Hi there!"
    or "<!Howdy.>"
    or "Greetings, human."
  say "What's your name?"

  when "My name is $name"
    with name = AMAZON.US_FIRST_NAME
    say "Hey! nice to meet you, $name."
    soundEffect happy.mp3
```
:::
</Feature>

<div class='feature-cards home-aligned'>

<FeatureCard image="/icons/compiler_160x96.png">

## The Compiler

Emits standard, highly performant JavaScript code ready to deploy to a host like AWS Lambda. Compile time checking of things like language model elements and asset references means fewer bugs to discover at runtime.

</FeatureCard>

<FeatureCard image="/icons/toolchain_160x96.png">

## The Toolchain

A one-step build and deploy system that seamlessly synchronizes your language model and deploys your skill endpoint, assets, and storage to AWS.

</FeatureCard>

<FeatureCard image="/icons/extensions_160x96.png">

## Extensions

Designed to be tweaked, Litexa extensions let you add new features to the compiler and toolchain, even add new syntax. Build tools to dig into what makes your team and project special.

</FeatureCard>

</div>

<Feature title="State Management" link="/book/state-management" link-text="Learn more about State Management">
::: slot description
Litexa's syntax is designed around the central idea of handling incoming intents based on the user's current state.
:::

::: slot code
``` coffeescript
askAboutRoses
  say "Do you prefer red or blue roses?"
  LISTEN microphone

  when "I like $color roses"
    or "$color ones"
    or "$color"
    with color = "red", "blue"

  say "Hey, I like $color ones too."
    or "Nice! I like $color ones too."
  END

 when AMAZON.RepeatIntent
  -> askAboutRoses
```
:::
</Feature>


<Feature title="Variables &amp; JS Interpolation" link="/book/expressions" link-text="Read the Variables and Expressions documentation">
::: slot description
Litexa variables can be easily persisted and retrieved between skill launches, and resolved request slot values are handled seamlessly. Additionally, JavaScript interpolation is effortless: JS values (including objects, arrays, and functions) can be directly accessed from within Litexa.
:::

::: slot code
``` coffeescript
# main.litexa
launch
  if @name
    say "Welcome back, @name."
    -> playGame
  else
    -> askName

askName
  say "What's your name?"

  when "My name is $name"
    with $name = AMAZON.US_FIRST_NAME

    say "Hi, {formatName($name)}"
    # store the result permanently
    @name = $name
```
``` javascript
// litexa/main.js
function formatName(name) {
  return `the most honorable ${name}`;
}
```
:::
</Feature>




<Feature title="Screen Devices" link="/book/screens" link-text="Read the Screens documentation">
::: slot description
For Alexa-enabled devices with a screen, Litexa supports easily building, sending, and validating both Alexa Presentation Language (APL) and <code>Display.RenderTemplate</code> directives.
:::

::: slot code
``` coffeescript
apl
  document: apl_doc.json
  data: apl_data.json
  commands: apl_commands.json

say "turning page"
apl
  commands: turn_page.json

soundEffect page_chime.mp3
say "page turned"
```
:::
</Feature>




<div class="stripe">
<div class="home-aligned">

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
</div>
</div>




<div class="faquestions">

<FAQuestion>

## How much does Litexa cost? Where does it come from?

Litexa is *free!*

Litexa is an Alexa Labs community-supported project (alpha) from the Alexa Games team at Amazon.
We (Alexa Games) have used Litexa to develop and ship 20+ Alexa skills, your mileage may vary.
Your feedback is welcome and we are happy to consider contributions.
Otherwise, you are free to use and modify this software as needed.
As with all open-source packages, please use them in accordance with the licenses assigned to each package.

For officially supported skill development tools, look for tools in the
[Alexa Skills Kit](https://developer.amazon.com/en-US/alexa/alexa-skills-kit/) like [Skill Flow Builder](https://developer.amazon.com/blogs/alexa/post/83c61d4e-ab3f-443e-bf71-75b5354bdc9e/skill-flow-builder) and the [ASK SDK](https://developer.amazon.com/docs/alexa-skills-kit-sdk-for-nodejs/overview.html).

</FAQuestion>



<FAQuestion>

## Does Litexa handle Alexa feature X?

Check out [The Book](/book/) for features that Litexa has value added syntax for. Don't see something you want to use? No sweat, Litexa lets you write your own directives from scratch, and whitelist incoming event names.

</FAQuestion>



<FAQuestion>

## Can I still use my JavaScript libraries?

Yes! Litexa compiles into a JavaScript closure that you can inject code into, in order to add symbols that will be visible to your Litexa code. In there you can refer to any external modules in the usual way, and thereby pass their symbols up to Litexa too.

</FAQuestion>



<FAQuestion>

## I really like writing in TypeScript/CoffeeScript can I still do that?

Hey, actually we do too! Beyond a certain level of complexity, it's nice to split up your presentation code from your business logic, and the Litexa/JavaScript boundary is a great fit for that. The litexa generate command has a series of options, including primary code language and bundling strategy, that will help you jump right in.

</FAQuestion>



<FAQuestion>

## Why a language?

We just really care about syntax, and getting any boilerplate out of the way so that we're as close as we can be to just iterating on content.

</FAQuestion>



<FAQuestion>

## Can I make any kind of Alexa skill with Litexa?

You know, we've mostly made games with it, so we can't say for sure. We'd very much love to hear about your experiences if you try something else though. Feel free to submit a pull request if you need something to change!

</FAQuestion>



<FAQuestion>

## What extensions and features are currently available?

* **litexa/deploy-aws:** A deployment module that pushes a skill to AWS using Lambda, DynamoDB, and S3.

* **litexa/apl:** An extension that makes working with the Alexa Presentation Language (APL) in your Litexa project more powerful, with shorthand for managing APL documents and common design patterns.

* **litexa/render-template:** An extension that supports easily building, sending, and validating a `Display.RenderTemplate` directive, the predecessor to APL.

* **litexa/assets-wav:** A WAV/MP3 composer that can combine multiple overlapping samples into a single MP3 stream, and a binding layer for use in Literate Alexa.

* **litexa/gadgets:** An extension for the Gadgets Skill API, which powers interaction with Echo Buttons (and potentially other Alexa Gadgets).

* Additionally, there is built-in support for [In Skill Purchasing (ISP)](/book/monetization.html) in the core package, and a [VSCode extension](/book/appendix-editor-support) that provides syntax highlighting for `.litexa` files. We've also provided documentation for how to [use Alexa features that Litexa does not yet support](/book/backdoor.html).

</FAQuestion>


</div>