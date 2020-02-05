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
skills through Litexa.

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

## Alexa Web API Interface

Integrating your skill with the Alexa Web API will allow it to both send and receive data
from your web app.

### Skill Manifest

Before your skill can send and receive data through the Alexa Web API, you will need to
specify the interface in your skill's manifest. You will need to include
`ALEXA_PRESENTATION_HTML` in your `skill.*` file to let Alexa know that you are using it.
For example, your skill manifest might look something like this:

```json
{
  "manifest": {
    "apis": {
      "custom": {
        "interfaces": [
          {
            "type": "ALEXA_PRESENTATION_HTML"
          }
        ]
  ...
}
```

### Directives

With Alexa Web API directives, you can send data to your web app from within your skill.

Use the `directive` keyword in your `*.litexa` files to add these directives to your
Alexa responses. You can get more information about the usage of the `directive` keyword
from our
[Litexa language reference](https://litexa.com/reference/#directive).

#### Start Directive

To start your web app, attach the `Alexa.Presentation.HTML.Start` directive to your skill's response.
Here's an example of what your Litexa code could look like:

```coffeescript
launch
    if HTML.isPresent()
      directive htmlStartDirective(webAppUrl)
    ...
```

And the `#htmlStartDirective()` function would return an object like this, and Litexa will add
it to your skill's response:

```javascript
function htmlStartDirective(url) {
    return {
        type: "Alexa.Presentation.HTML.Start",
        configuration: {
            timeoutInSeconds: 1000
        },
        data: {},
        request: {
            uri: url,
            method: "GET",
            headers: {}
        },
        transformers: {}
    };
}
```

#### HandleMessage Directive

To send data to your web app, attach the `Alexa.Presentation.HTML.HandleMessage`
directive to your skill's response. Here's an example of what your Litexa code could look like:

```coffeescript
fooState
  when MyIntent
    directive htmlHandleMessageDirective(message)
  ...
```

And the `#htmlHandleMessageDirective()` function would return an object like the one below, and
Litexa will add it your skill's response:

```javascript
function htmlHandleMessageDirective(message) {
    return {
        type: "Alexa.Presentation.HTML.HandleMessage",
        message: message,
        transformers: {}
    };
}
```

### Events

With Alexa Web API events, your skill can receive & handle data sent from your web app.

#### Message Event

To handle data that is sent from your web app, look for the `Alexa.Presentation.HTML.Message`
event in your `*.litexa` files like you would for an intent-type event (using the `when` keyword).
For example:

```coffeescript
barState
    when Alexa.Presentation.HTML.Message
      say "I received a message from the web app!"
    ...
```

## Advanced Features

### 'mark' SSML Tags

In your `.litexa` files, you can add `mark` SSML tags to your speech, like so:

```coffeescript
launch
  say "Hello, World!"
  HTML.mark("screen:blue")
  END
```

This will add a substring like `<mark name="screen:blue"/>` to your response's speech.
This is useful for your HTML runtime in that, when it receives the Alexa response,
the marks can be used to trigger HTML events that interleave with SSML playback.

## Relevant Resources

For more information, please refer to the official Alexa Web API for Games documentation:

* [Alexa Web API 
for Games Announcement](https://developer.amazon.com/en-US/blogs/alexa/alexa-skills-kit/2019/11/apply-for-the-alexa-web-api-for-games-developer-preview)

