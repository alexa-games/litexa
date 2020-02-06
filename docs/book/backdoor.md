# What About Other Features?

Litexa supports Alexa features through a mixture of code shipped with the Litexa core package
and code added by [Litexa extensions](extensions.html), extra packages that you install alongside
Litexa that can add support for things like events, directives, new Litexa statements and runtime
code.

There are plenty of wonderful Alexa features that Litexa does not yet directly support, but you are
not prevented from using them with a Litexa project! Here are the extension points where you can
convince Litexa you know better, and have it step out of your way. If you opt to apply these
extension points in your own extension, please also refer to the instructions found in
[Litexa extensions](extensions.html).

## Reading and Modifying Litexa's `context`

Litexa has a `context` object that is accessible within the scope of any Litexa code, and can be
handed off to inline code as a function parameter:

```coffeescript
# main.litexa
launch
  printObject(context)
```

```js
// main.js
printObject = function(obj) { console.log(JSON.stringify(obj)); }
```

This Litexa `context` is recreated for every new skill request, and contains the following data:

1. incoming request data (e.g. session attributes)
2. pending response data (e.g. pending output speech)
3. DB data (e.g. persistent and transient variables)
4. utility data (e.g. skill launch time stamp)

Let's take a closer look at each of these in turn, along with some common use cases.

### 1) Incoming Request Data

The full incoming request, along with session and system information, is available in
`context.event`:

```json
{
  "version": "1.0",
  "session": { // SESSION DATA
    "sessionId": "amzn1.echo-api.session.someId",
    "application": {
      "applicationId": "amzn1.ask.skill.someId"
    },
    "attributes": {},
    "user": {
      "userId": "amzn1.ask.account.someId"
    }
  },
  "context": { // SYSTEM DATA
    "System": {
      "device": {
        "deviceId": "amzn1.ask.device.someId",
        "supportedInterfaces": {
          "Alexa.Presentation.APL": {},
          "Display": {}
        },
        "apiEndpoint": "https://api.amazonalexa.com",
        "apiAccessToken": "someAccessToken"
      }
    },
    "Viewport": {
      "experiences": [
        {
          "arcMinuteWidth": 246,
          "arcMinuteHeight": 144,
          "canRotate": false,
          "canResize": false
        }
      ],
      "shape": "RECTANGLE",
      "pixelWidth": 1024,
      "pixelHeight": 600,
      "dpi": 160,
      "currentPixelWidth": 1024,
      "currentPixelHeight": 600,
      "touch": [
        "SINGLE"
      ],
      "video": {
        "codecs": [
          "H_264_42",
          "H_264_41"
        ]
      }
    }
  },
  "request": { // REQUEST DATA
    "type": "IntentRequest",
    "requestId": "amzn1.echo-api.request.2f164393-f7c7-410d-8819-eccd49a7f26f",
    "timestamp": "2017-10-01T22:02:10.000Z",
    "locale": "en-US",
    "intent": {
      "name": "MY_NAME_IS_NAME",
      "slots": {
        "name": {
          "name": "name",
          "value": "John"
        }
      }
    }
  }
}
```

:::tip Request Data Shortcuts
There are some useful request data shortcuts available in Litexa:

* `context.event.request` is available as [$request](/reference/#request).
* `context.event.request.intent.slots` values are populated directly in
[slot variables](/reference/#slot-variables). For instance:

    ```coffeescript
    when "my name is $name"
      with $name = AMAZON.US_FIRST_NAME
      say "hello $name"
    ```

    The intent handler (`say "hello $name"`) can directly reference a slot name, which will end up
    populated with whichever value the user utterance was converted to (for instance, as seen in the
    above request data, "John").

* `context.event.request.requestId` is available with the shortcut `context.requestId`
:::

:::tip Request Data Use Cases
While Litexa makes most request data available/modifiable without requiring the `context` object
(see shortcuts above), there are several viable scenarios that currently require reading
the `context` object directly, such as:

* visibility and manipulation of `context.event.session.attributes`
* visibility of supported interfaces in `context.event.context.System`
* visibility of device screen specs in `context.event.context.Viewport`
* etc.
:::

### 2) Pending Response Data

The Litexa `context` tracks the following data to be included in any pending response:

```json
{
  "say": [],        // pending outputSpeech (as specified by 'say' statements)
  "reprompt": [],   // pending reprompt speech (as specified by 'reprompt' statements)
  "directives": [], // pending directives (as specified by the 'directive', 'card',
                    // monetization, and extension statements)
  "shouldEndSession": false // value explicitly set by 'END' statement,
                            // or implicitly set by other statements
}
```

:::tip Response Data Use Cases
The response data in `context` can be used to read, modify, or validate the pending response.
It also allows for changing the response outside of Litexa code, for instance by handing off
the context to an inline function:

```coffeescript
# main.litexa
launch
  addCustomSSML(context)
```

```js
// main.js
addCustomSSML = function(context) { context.say.push("[myCustomSSML]"); }
```

Modifying response data can become especially useful when authoring a custom
[Litexa extension](extensions.html). For instance, the `@litexa/apl` extension keeps track of all
APL-related data in a newly added `context.apl` object.
:::

### 3) DB Data

`context.db` allows for directly accessing the DB instance used by Litexa. As an alternative to
using [`@ variables`](/reference/#variable) to read and write DB data, the same can be achieved by
directly invoking `context.db.write(String key, data)` and `context.db.read(String key)`.

Among other skill information, the `context.db` object tracks [local variables](/reference/#local)
and [@ variables](/reference/#variable):
```json
{
  "db": {
    "variables": {
      "myKey": {
        "myData"         // as saved by: @myKey = "myData"
      }
    }
  },
  "cache": {
    "__stateLocals": {
      "myVar": "myValue" // as saved by: local myVar = "myValue"
    }
  }
}
```

:::warning Litexa-internal DB data
DB variables stored with the private `'__'` prefix should generally be left untouched: Modifying
them could negatively impact skill functionality, as they are usually relied on by Litexa's core
or extension logic.
:::

### 4) Utility Data

Finally, the `context` object provides some useful utility information for the currently active
session:

```js
{
  "now": 1506895265000,      // time (in milliseconds) of current session launch
  "language": "default"      // current skill session's language
  "shouldEndSession": false, // modified by the 'END' statement
  "settings": {
    "resetOnLaunch": true    // modified by the 'set [setting] [boolean]' statement
  },
  "traceHistory": [          // all states that were visited in current session
    "launch"
  ],
  "monetization": [          // overview of all linked in-skill products
    "inSkillProducts": [
      // [reference name]: 'ENTITLED'|'NOT_ENTITLED'
      { 'myProduct':       'ENTITLED' }
    ]
  ]
}
```

:::tip Utility Data Use Cases
This utility data can serve various purposes:

* `context.language` can be used to handle the appropriate language in a
[Litexa extension](extensions.html). Note, that this is the language defined by Litexa:
  * any locale that has no specific `languages` directory, as detailed in the documentation
  on [Localization Project Structure](localization.html#project-structure), is mapped to `default`.
  * all other locales are mapped to the same name used for their `languages` directory. This would
  be either a specific locale (`es-es`) or a language code spanning multiple locales (e.g. `es`
  would override the locales `es-ES` and `es-MX`).
* `context.traceHistory` can be used for troubleshooting or analytics
* `context.now` can be used to enable time-based skill variations, such as:

```coffeescript
launch
  if minutesBetween(context.now, @lastLaunchTime) < 15
    say "We spoke less than 15 minutes ago, did you miss me?"
  @lastLaunchTime = context.now
```

:::

In summary, the Litexa `context` object is a good starting point for extending Litexa's
capabilities, be it through external [Litexa extensions](extensions.html), or through
skill-specific in-code `context` handlers.

## Modifying the Response Object

Modifying the skill response is currently possible in one of three ways:

1. indirectly, by [modifying response properties](#_2-pending-response-data) in the Litexa
`context` object, as described above.
2. directly, by writing a [Litexa extension](extensions.html#_3-runtime-extension) with a
`beforeFinalResponse` handler which would receive the full response object prior to it being sent.
3. directly, by writing a function in your skill's project that you then assign to Litexa's
`responsePostProcessor` handler.

## Accepting Novel Events

Coming soon!

## Sending Novel Directives

Most of the commands you send as part of a skill's response will
be in the form of *directives*, which are included as JSON objects
in a skill response. See the [ASK documentation on skill responses](https://developer.amazon.com/docs/custom-skills/request-and-response-json-reference.html#response-object)
for more information about directives in general.

Several Litexa statements, like `screen` or `card`,
will generate directives as part of their functionality. These
will also insert or assert any other requirements associated
with using the command, such as injecting an API interface
declaration into your `skill.json` manifest, or giving you
a compile error should the command require an intent you haven't
defined in your skill's language model.

You can also directly create any directive yourself, by using the
`directive` statement. You may want to do this if it's more
convenient to generate many directives, or template their
contents in your code somehow. The statement takes as an argument
an expression, usually a function call that resolves to either a
single JSON directive object, or an array of JSON directives.

For instance, the following skill returns a manually constructed
`AudioPlayer.Play` directive:

```coffeescript
launch
  say "Get ready to groove in 3. 2. 1."
  directive playJazzyMusic()
```

```javascript
function playJazzyMusic(){
  return {
    type: "AudioPlayer.Play",
    playBehavior: "valid playBehavior value such as REPLACE_ALL",
    audioItem: {
      stream: {
        url: "https://cdn.example.com/url-of-the-stream-to-play",
        token: "aStreamToken",
        offsetInMilliseconds: 0
      },
      metadata: {
        title: "Downright Jazzy",
        subtitle: "Were you ready for that jazz?",
        art: {
          sources: [
            {
              url: "https://cdn.example.com/url-of-the-album-art-image.png"
            }
          ]
        },
        backgroundImage: {
          sources: [
            {
              url: "https://cdn.example.com/url-of-the-background-image.png"
            }
          ]
        }
      }
    }
  }
}
```

By default, Litexa will throw an error during testing if your
skill generates a directive it does not recognize. Additional
directive types may be supported by Litexa extensions, for
example the [`@litexa/apl`
extension](/book/screens.html#alexa-presentation-language), in
which case installing the extension will remove the error.

In the case that no extension exists to support the directive
yet, you can inform Litexa that you've vouched for the type and
that it should assume it is correct:

1. You will need to add the desired directive's type to the
   `directiveWhitelist` field of your Litexa project's
   `litexa.config.*` as seen below:

    ```json
    {
      "name": "myFirstProject",
      "deployments": { ... },
      "directiveWhitelist": [
        "AudioPlayer.Play"
      ]
    }
    ```

2. If the directive in question requires an interface declaration,
   then you should add such to your `skill.*` file manually.
   See the [ASK documentation on interfaces](https://developer.amazon.com/docs/smapi/skill-manifest.html#customInterface-enumeration)
   for more information on the various available interface
   declarations.

    ```json
    {
      "manifest": {
        ... other contents
        "apis": {
          "custom": {
            "interfaces": [
              {
                "type": "AUDIO_PLAYER"
              }
              ... other interfaces
            ]
          }
        }
      }
    }
    ```

For directives supported by Litexa extensions, any
generated directives will be validated for correct content,
raising an error during compilation so that you can catch it
as early as possible. Directives that you vouch for manually
in the whitelist though, offer no such protection, so an
invalid directive won't be caught until runtime. In those
cases, refer to your Litexa logs to discover what the problem is.

See the [chapter on testing](/book/testing.html) for more
information on tools you have available to help trap and
correct any errors.

## Modifying the Language Model

Coming soon!

## Customizing the DB Key

By default, Litexa keys any DB entries by the skill session's device ID. If required, this DB key
can be overridden by adding the following function anywhere in the skill's inline code.

```js
// The global `litexa` namespace contains compile-time objects at runtime.
// `overridableFunctions` can be redefined by assigning them to new functionality.
litexa.overridableFunctions = litexa.overridableFunctions
                              ? litexa.overridableFunctions
                              : {};

/* The `identity` parameter will have the following structure:
{
  requestAppId,  // = System.application.applicationId
  userId,        // = System.user.userId
  deviceId,      // = System.device.deviceId
  litexaLanguage // = Litexa language (e.g. 'default') for request's locale
}
*/
// Now, let's override the DB key generation.
litexa.overridableFunctions.generateDBKey = function(identity) {
  // Create and return the desired DB key.
  return `${identity.deviceId}|${identity.litexaLanguage}`;
};
```
