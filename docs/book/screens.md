# Screens

## Introduction

Certain Alexa-enabled devices with screens support skills using both screen
and voice interactions. As of March 2018, the list of these devices along
with their [specifications](https://developer.amazon.com/docs/custom-skills/display-and-behavior-specifications-for-alexa-enabled-devices-with-a-screen.html#display-specifications-for-alexa-enabled-devices-with-a-screen)
is:

| Device            | Width (px)  | Height (px) | DPI  | Shape | Input Type | Aspect Ratio|
| ------------------|:------------|:------------|:-----|:------|:-----------|:------------|
| Echo Show 1st Gen | 1024        | 600         | 170  | rect  | touch      | 16:9        |
| Echo Show 2nd Gen | 1280        | 800         | 170  | rect  | touch      | 16:9        |
| Echo Spot         | 480         | 480         | 274  | round | touch      | 1:1         |
| Fire TV Cube      | 1920        | 1080        | 320  | rect  | dpad       | 16:9        |
| Fire HD 8         | 1200        | 800         | 320  | rect  | touch      | 16:10       |
| Fire HD 10        | 1920        | 1200        | 320  | rect  | touch      | 16:10       |

::: tip
When developing Alexa skills, adding graphical elements to an otherwise voice-first
experience can significantly enrich the experience for screen users. That said, Alexa skills
should fully support non-screen devices (e.g. `Echo Dot`, `Echo Plus`), and any graphical
elements should be considered supplemental.
:::

Alexa currently supports two methods for showing and managing screens:

* `Alexa Presentation Language (APL)`
  * recommended for rich interactions and device customizations
  * supported by the `@litexa/apl` module (detailed below)

* `Display Render Templates`
  * easier to use, but restrictive (static, one-size-fits-all, pre-defined layouts)
  * supported by the `@litexa/render-template` module

::: tip NOTE
If the capabilities of `render templates` are sufficient for your skill's needs, detailed
documentation can be found here: [Display Render Template](/book/appendix-render-template.html)
:::

## Alexa Presentation Language

Alexa's APL interface allows for curating complex voice and visual experiences on compatible devices
(see list in [Introduction](#introduction)). Here are some examples of what you can do with APL:

* add text formatting and graphical layout manipulation similar to HTML/CSS
* use conditional statements to customize experience, for example per device type to select
differently sized images per resolution and aspect ratio
* convert on-screen text to speech, and add Karaoke-style highlighting while it's spoken
* show and manipulate slide-shows and scrollable lists on device
* use `JSON` style object data binding and manipulation
* add user touch event listeners

Additionally, APL provides the benefit of being able to queue logic and commands on device, removing
the necessity to "hop" between the skill and device repeatedly, and thus reducing latency.

## APL Directives

There are two different APL directives:

* [Render Document Directive](https://developer.amazon.com/docs/alexa-presentation-language/apl-render-document-skill-directive.html):
Sends a required document with graphical layouts and components, and optional data sources.
* [Execute Commands Directive](https://developer.amazon.com/docs/alexa-presentation-language/apl-execute-command-directive.html):
Sends one or more commands, which are tied to a document (in the same or a past response), and execute in sequence
upon arrival.

The module `@litexa/apl` supports easily building, sending, and validating APL directives.
Please find the information on how to install and use this module (along with some general
APL usage information) below.

::: tip
When installed, the `@litexa/apl` will validate any APL directives added to a response,
even if the directive wasn't built using the module's APL statement.
:::

::: warning
The [Display.RenderTemplate](https://developer.amazon.com/docs/custom-skills/display-interface-reference.html)
directive (as supported by the `@litexa/render-template` extension) is not compatible with these APL directives.
The two can still both be used in the same skill, as long as they aren't sent in the same response. If they are,
the APL directive(s) will take precedence and the `Display.RenderTemplate` directive will be removed!
:::

## Installation

The module can be installed globally, which makes it available to any of your Litexa projects:

```bash
npm install -g @litexa/apl
```

If you alternatively prefer installing the extension locally inside your Litexa project for the sake of tracking the
dependency, just run the following inside of your Litexa project directory:

```bash
npm install --save @litexa/apl
```

This should result in the following directory structure:

```stdout
project_dir
├── litexa
└── node_modules
    └── @litexa
        └── apl
```

## New Statement

When installed, the module adds a new `apl` statement to Litexa's syntax, which can be used to build and send APL
directives from within Litexa.

The `apl` statement supports the following attributes:

* `document` ... requires a [Document](#document) `object`
* `data` ... requires a [Data](#data) `object`
* `commands` ... requires either a single `object` or `array` of [Commands](#commands) `objects`
* `token` ... requires a `String` identifier to be attached to the APL directives

There are two options for supplying the objects required by `document`, `data`, and `commands`:

1. Use a (quoted or unquoted) path to a JSON file. This path should be relative to your skill's `litexa` directory.
Doing this will assign the JSON file's contents to the indicated attribute (and throw a compile-time error, if the
file can't be found). This option is meaningful for anything static (e.g. a fixed `document`).

    For example, assuming the following project structure:

    ```stdout
    project_dir
    └── litexa
        └── my_doc.json
        └── apl
            └── my_data.json
    ```

    The above files could be referenced like so:

    ```coffeescript
      apl
        document: my_doc.json
        data: apl/my_data.json
    ```

2. Use a function in external code to generate the `object`/`array` and supply the output. This option is meaningful
for anything dynamic (e.g. `data` or `commands` which depend on certain parameters).

    ```javascript
      function generateMyData(args) {
        // ...
      }
    ```

    ```coffeescript
      local myData = generateMyData(args)
      apl
        data: myData
    ```

More information on how to use each of these attributes is provided below.

### Document

As a reminder, every `APL.RenderDocument` directive is required to have a document (this means sending only data is not
possible).

Here's an example for sending a `document` with minimal properties via `apl`.

```coffeescript
apl my_doc.json

# The above shorthand for specifying a document is equivalent to:
apl
  document: my_doc.json
```

```json
// my_doc.json
{
  "type": "APL",
  "version": "1.0",
  "mainTemplate": {
    // required components for APL to inflate on the device upon activation
  }
}
```

::: tip
`apl` will automatically add default values for `type` and `version`, if missing.
:::

Beyond the required `mainTemplate`, a `document` can optionally include `import`, `resources`, `styles`, and `layouts`.
For more information on these, please refer to the official
[APL Document](https://developer.amazon.com/docs/alexa-presentation-language/apl-document.html) documentation.

::: tip
If you prefer, you can specify a `document` that wraps either or both of `document` and `data`. This is also
the format provided by any [APL Authoring Tool](https://developer.amazon.com/alexa/console/ask/displays/?) exports, so
directly referencing any exported examples as your `document` will work.

```json
// my_doc.json:
{
  "document": {
    // your APL document
  },
  "data": { // or alias: "datasources"
    // your APL data
  }
}
```

:::

::: tip
To customize behavior per device, you can use the data-bound `viewport` variable in `when` conditionals,
to check device properties. Here are a couple examples:

```json
"resources": [
  {
    "description": "Stock color for the light theme",
    "colors": {
      "colorTextPrimary": "#151920"
    }
  },
  {
    "description": "Stock color for the dark theme",
    "when": "${viewport.theme == 'dark'}",
    "colors": {
      "colorTextPrimary": "#f0f1ef"
    }
  }
]
"layouts": {
  "items": [
    {
      "when": "${viewport.shape == 'round'}",
      "type": "Container",
      (...)
      // use this container, if running on the Echo Spot
    }
    {
      "type": "Container",
      (...)
      // otherwise, use this container
    }
  ]
}
```

For more information on `viewport` and which characteristics of the display device it includes, please refer to the
[Viewport Property](https://developer.amazon.com/docs/alexa-presentation-language/apl-viewport-property.html)
documentation.
:::

### Data

As a reminder, every `APL.RenderDocument` directive can optionally include "datasources". This data is a collection of
skill-author defined objects which can then be referenced in an APL document's components.

Here's an example of sending some `data` via `apl`, and using it in a `document`:

```coffeescript
apl
  document: my_doc.json
  data: my_data.json
```

```json
// my_data.json
// datasources:
{
  "myDataObject": {
    "type": "object",
    "properties": {
      "title": "This is myDataObject's title."
    }
  }
}
```

The above `data` is then accessed with the parameter `payload`:

```json
// my_doc.json
// document:
{
  "mainTemplate": {
    "parameters": [
      "payload"
    ],
    "item": {
      "type": "Text",
      "text": "${payload.myDataObject.properties.title}"
    }
  }
}
```

::: warning
The data reference "payload" is the default, but could be replaced with any `String`. However, it is important to only
have a single `String` in `parameters` (adding anything else will break the document).
:::

For more information on what kind of `data` you can use, please refer to the
[APL Data Sources and Transformers](https://developer.amazon.com/docs/alexa-presentation-language/apl-data-source.html)
documentation.

### Commands

As a reminder, the `APL.ExecuteCommands` directive is sent with a single command `object`, or an `array`
of multiple commands. These commands are then executed in sequence.

Here's an example of using `commands` via `apl`, to show pages in a `document`'s `Pager`:

```coffeescript
apl
  document: my_pager.json
  commands: pager_commands.json
```

```json
// my_pager.json:
{
  "mainTemplate": {
    "item": [
      {
        "type": "Pager",
        "id": "pagerComponentId",
        "items": [
          {
            "type": "Text",
            "text": "Page 1" // page 1 will inflate first
          },
          {
            "type": "Text",
            "hint": "Page 2"
          },
          {
            "type": "Text",
            "hint": "Page 2"
          }
        ]
      }
    ]
  }
}
```

```json
// pager_commands.json
[
  {
    "type": "Idle",
    "delay": 2000 // let page 1 show for 2 secs
  },
  {
    "type": "SetPage",
    "componentId": "pagerComponentId", // above Pager's ID
    "value": 2 // turn to page 2
  },
  {
    "type": "Idle",
    "delay": 2000 // let page 2 show for 2 secs
  },
  {
    "type": "SetPage",
    "componentId": "pagerComponentId",
    "value": 3 // turn to page 3
  }
]
```

::: tip
You can send `commands` without a `document` or `data`. If a `document` is active on the device, the `commands` will
execute accordingly. Otherwise, they will be ignored.

This means you can send a `document` at some point in your skill, and then choose to send detached `commands`
in future responses.
:::

### Tokens

The `apl` `token` defaults to "DEFAULT_TOKEN", if not specified. It's important to note that an `ExecuteCommands`
directive's token must match the displaying `RenderDocument`'s token for the commands to run.

::: warning
As of March 2018, commands with tokens not matching the active document incorrectly do work on the
[ASK Developer Console](https://developer.amazon.com/alexa/console/ask). They are properly suppressed
on APL-compatible devices.
:::

Additional to insuring that `commands` only run atop the intended `document`, tokens can also be used to allocate
[User Events](#user-events), as demonstrated farther below.

### Merging Fragments

The `apl` statement supports aggregating multiple instances of `document`, `data`, `commands`. What does this mean?
If your skill encounters multiple `apl` statements before sending a response (e.g. `apl` statements in different
`states`), it will aggregate any such "fragments" before sending them in APL directives. Here's an example:

```coffeescript
stateOne
  apl doc_one.json
    data: data_one.json
    commands: commands_one.json
  -> stateOne
stateTwo
  apl doc_two.json
    data: data_two.json
    commands: commands_two.json
  -> stateThree
stateThree
  apl
    document: ["doc_three.json"]
    data: data_three.json
    commands: commands_three.json

# The above state sequence would merge all three documents,
# data, and commands prior to sending the response.
```

This behavior is useful for adding state-specific content or instructions to your skill's APL behavior, or
interleaving `commands` with Litexa `say` or `soundEffect` statements.

::: warning
Since the `document` can only meaningfully have one `mainTemplate` (i.e. active template), any consecutively
encountered `document` fragments that have a `mainTemplate` will overwrite the previous `mainTemplate` (with a
logged warning)!

Make sure any possible state flow with at least one `apl` `document` always finds a valid `mainTemplate`, and wouldn't
accidentally overwrite a previous `document`'s required `mainTemplate`.
:::

::: tip NOTE
If a Litexa state flow encounters consecutive `apl` `token`s prior to sending a response, it will simply use the
latest.
:::

### Referencing Assets

Beyond using existing URLs, it is possible to reference `assets` files in any `apl` `document` or `data`.
To do so, simply add the placeholder prefix `assets://` to your file's name. For example:

```json
  {
    "type": "Image",
    "source": "assets://my_image.jpg",
    "width": 300,
    "height": 300
  }
```

Assuming there's a `my_image.jpg` in your `assets` directory, the above reference would then be replaced with the
S3 link of the deployed file.

### Interleaving Sound

Litexa's `say` and `soundEffect` are usually added to the response
[outputSpeech](https://developer.amazon.com/docs/custom-skills/request-and-response-json-reference.html#outputspeech-object).
However, any `outputSpeech` is spoken *before* APL commands are executed.

Using the `apl` statement, if a `document` is pending, `say` and `soundEffect` will be converted to APL commands and
interleave in the expected sequence. For example:

```coffeescript
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

would produce the following output sequence:

1. APL would execute commands in `apl_commands.json`
2. Alexa would say "turning page"
3. APL would execute commands in `turn_page.json`
4. Alexa would play the sound effect `page_chime.mp3`
5. Alexa would say "page turned"

::: tip NOTE
The above sequencing will only take place if a `document` is found before sending the response.

Reason: Converting any sound output to APL requires insertions in the `document`. Creating a new `document` to
accomplish this might unintentionally replace an active `document` on the device.

Summary: If no `document` is pending, no interleaving will take place, and any `say` or `soundEffect` will normally
play through `outputSpeech`. In the above example, if no `apl` `document` were defined, the output sequence would be
2-4-5-1-3.
:::

::: warning
As of March 2018, sound effects incorrectly do not work on the
[ASK Developer Console](https://developer.amazon.com/alexa/console/ask). They do however work on APL-compatible devices.
:::

## User Events

APL can trigger user events back to the skill when the user presses an on-screen
[TouchWrapper](https://developer.amazon.com/docs/alexa-presentation-language/apl-touchwrapper.html).
Here's an example:

```json
{
  "type": "TouchWrapper",
  "id": "My Touchable",
  "item": {
    "type": "Text",
    "text": "I am a touchable that will send an event back to the skill."
  },
  "onPress": {
      "type": "SendEvent",
      "arguments": [
          "I am coming from My Touchable."
      ]
  }
}
```

A skill user touching the touchable would then trigger this `Alexa.Presentation.APL.UserEvent`:

```json
{
  "type": "Alexa.Presentation.APL.UserEvent",
  "requestId": "...",
  "timestamp": "...",
  "locale": "en-US",
  "arguments": [
      "I am coming from My Touchable."
  ],
  "components": {},
  "source": {
      "type": "TouchWrapper",
      "handler": "Press",
      "id": "My Touchable",
      "value": false
  },
  "token": "This is the token of the APL document that sourced this event."
}
```

You can optionally handle any such user events in your code with something like:

```coffeescript
## In litexa:
when Alexa.Presentation.APL.UserEvent
  handleUserEvent($request)
```

```javascript
// In your external code (e.g. JavaScript):
function handleUserEvent(request) {
  switch(request.token) {
    // could ignore a token from an outdated document
  }
  switch(request.source.id) {
    // could trigger behavior specific to this touchable
    // (e.g. send command to scroll a visible list)
  }
  switch(request.arguments) {
    // could send and evaluate something like data-bound arguments
  }
}
```

## Intent Handling Requirements

When using an APL directive, the built-in `AMAZON.HelpIntent` must be handled by the skill (i.e. included in at
least one `when` listener). This can be done via state-specific handlers, or a `global` handler:

```coffeescript
global
  when AMAZON.HelpIntent
    -> helpState
```

## Checking APL Support

If APL is not supported on the device running your skill, any `apl` statements will be ignored, and everything else
will work normally (e.g. `say` and `soundEffect` will run via `outputSpeech` instead of APL commands).

To check APL support at runtime, the following command can be used from within Litexa or external code:

```coffeescript
if APL.isEnabled()
  # say "APL is supported on this device."
else
  # say "APL is not supported on this device."
```

::: tip
This availability check should be used to curate any skill for both APL and non-APL devices.
:::

## Relevant Resources

For more information, please refer to the official APL documentation:

* [Alexa Presentation Language](https://developer.amazon.com/docs/alexa-presentation-language/apl-overview.html)
* [Render Document Directive](https://developer.amazon.com/docs/alexa-presentation-language/apl-render-document-skill-directive.html)
* [Data Sources and Transformers](https://developer.amazon.com/docs/alexa-presentation-language/apl-data-source.html)
* [Execute Commands Directive](https://developer.amazon.com/docs/alexa-presentation-language/apl-execute-command-directive.html)
* [APL Document](https://developer.amazon.com/docs/alexa-presentation-language/apl-document.html)
* [APL Data Types](https://developer.amazon.com/docs/alexa-presentation-language/apl-data-types.html)
* [APL Standard Commands](https://developer.amazon.com/docs/alexa-presentation-language/apl-standard-commands.html)
* [APL Authoring Tool](https://developer.amazon.com/alexa/console/ask/displays/?)
