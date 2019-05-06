# What About Other Features?

Litexa supports Alexa features through a mixture of code 
shipped with the Litexa core package and code added by 
Litexa *extensions*, extra packages that you install alongside 
Litexa that can add support for things like events, 
directives, new Litexa statements and runtime code.

There are plenty of wonderful Alexa features that Litexa does
not directly support, but you are not prevented from 
using them with a Litexa project! Here are the extension 
points where you can convince Litexa that you know better, 
and that it should step out of your way.


## Accepting Novel Events


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


## Directly Modifying the Response Object

## Modifying The Language Model