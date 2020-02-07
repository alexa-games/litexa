# Litexa HTML Support

This module adds support for the Alexa Web API for Games.

The Alexa Web API for Games allows you to use existing web technologies and tools to create
visually rich and interactive voice-controlled game experiences. You'll be able to build
for multimodal devices using HTML and web technologies like Canvas 2D, WebAudio, WebGL,
JavaScript, and CSS, starting with Echo Show devices and Fire TVs.


**NOTE**: The Alexa Web API for Games is currently in Developer Preview. To gain access
to its features & documentation, visit the [Alexa Developer
Blog](https://developer.amazon.com/en-US/blogs/alexa/alexa-skills-kit/2019/11/apply-for-the-alexa-web-api-for-games-developer-preview)
for sign-up information.

## Installation

**WARNING**: The use of this extension is currently reserved for those in the
Alexa Web API for Games Developer Preview. If you are not in the Developer Preview
and you have this extension installed, you will not be able to deploy your Alexa
skills through Litexa. As an additional note, the API is subject to change, which
may make this extension out of date.

The module can be installed globally, which makes it available to any of your
Litexa projects:

```bash
npm install -g @litexa/html
```

If you alternatively prefer installing the extension locally inside your Litexa project,
for the sake of tracking the dependency, just run the following inside of your Litexa
project directory:

```bash
npm install --save @litexa/html
```

This should result in the following directory structure:

```stdout
project_dir
├── litexa
└── node_modules
    └── @litexa
        └── html
```

**WARNING**: Unlike most of the other Litexa extensions which conditionally add the
interface declaration based on whether or not they were used in your skill, the
`@litexa/html` extension will always add the HTML interface to your skill. Thus, if you
do not plan on using them for all skills, it may be best to use the local installation
option for each project.

## Litexa's Alexa Web API Interface

Integrating your skill with the Alexa Web API will allow it to both send and receive data
from your web app.

### Skill Manifest

This extension automatically adds the `ALEXA_PRESENTATION_HTML` interface declaration to
your skill manifest upon deployment.

### Usage

#### HTML.isHTMLPresent()

This extension adds a global `HTML` object you can use in both Litexa and code files. It
has one function, which is to detect whether or not HTML is supported on the user device
the skill is running on. This is best used in conjunction with conditionally sending HTML
directives, since you may want to fall back to APL if HTML is not supported on a device.

For example:

```coffeescript
launch
  if HTML.isHTMLPresent()
    directive htmlStartDirective(webAppUrl) # returns `Alexa.Presentation.HTML.Start` directive; this will launch the web app
  else
    apl apl/splashScreen.json # the apl statement conditionally sends the directive based on if the device supports it
  ...
```

**WARNING**: Do not use APL and HTML directives in the same response. The user's device
will likely experience undesired behavior.

#### Directives

You can use the [`directive`](https://litexa.com/reference/#directive) keyword to add
HTML directives to your skill responses.

#### Events

To handle data that is sent from your web app, add a `when` listener for the
`Alexa.Presentation.HTML.Message` event.

```coffeescript
waitForTransmission
  when Alexa.Presentation.HTML.Message
    say "I received a message from the web app!"
    switch $request.message # payload from web app
      ...
```

## Relevant Resources

For more information, please refer to the official Alexa Web API for Games documentation:

* [Alexa Web API 
for Games Announcement](https://developer.amazon.com/en-US/blogs/alexa/alexa-skills-kit/2019/11/apply-for-the-alexa-web-api-for-games-developer-preview)

