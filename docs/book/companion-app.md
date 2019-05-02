# The Companion App

The Alexa companion app is a quick and easy way to send additional information to the user from a 
skill. There are different platforms in which the companion app can be run, including most web 
browsers and Android/iOS apps.

Now that you have your Litexa project up and running, it is time to explore the options you have
for using the companion app.

## What can I do with the companion app?

Skills can display [Alexa Skill Cards](https://developer.amazon.com/docs/custom-skills/include-a-card-in-your-skills-response.html)
in the companion app, to describe or enhance the skill's voice interaction.

Litexa has a `card` statement which allows for easily sending such a card to the companion app.

You can use cards in your Alexa skill to:
 * include images for headless Echo devices, for more context
 * provide users with information they may want to keep or view later
 * help debug skills by sending text down to the card from the skill


## How do I use cards with my Litexa project?

To add a card to a reponse in Litexa, simply add the statement `card` in any of the following formats:

1. One-liners: `card <Title of card>, <optional image>, <optional content of card>`

```coffeescript
card "Welcome", image.png, "This is my wonderful image of a card"
...
card "Welcome", "This is my wonderful card"
...
local cardImage = "image.png"
card "Welcome", cardImage
...
card "Welcome Card"
```

2. Multiple-Line declaration
```coffeescript
local filename = "image.png"
card "Welcome!"
  image: filename
  content: "Some alternative content to put on the card.
    And a second line of it too."
```

For any images you would like in the card, you can place these files in your 'litexa/assets' folder and
reference them by name. For more information on assets, refer to the [Litexa Assets](/book/presentation.html#asset-file-references)
documentation.
```coffeescript
card "Welcome @name", image.png  # uses deployed litexa/assets/image.png
```

Variable interpolation is supported in the same manner as with the `say` statement:
```coffeescript
card "Welcome, Player {getCurrentPlayerNumber()}"
```

:::tip One card per response
Be careful not to have multiple `card` statements in one response. Litexa will safeguard to make sure
only the last `card` statement is included in the response, as Alexa doesn't support multiple
simultaneous cards.
:::


## Card Types

There are four types of cards supported by the Alexa companion app, which are detailed in this 
[Overview of cards](https://developer.amazon.com/docs/custom-skills/include-a-card-in-your-skills-response.html#overview-of-cards).
Below are JSON samples for each of these card types:

```json
// Standard Card
{
  ...
  "response": {
    ...
    "card": {
      "type": "Standard",
      "title": "Welcome",
      "text": "This is my wonderful card",
      "image": {
        "smallImageUrl": "https://example/smallImage.png",
        "largeImageUrl": "https://example/image.png"
      }
    }
  }
}

// Simple Card
{
...
  "card": {
    "type": "Simple",
    "title": "Welcome",
    "content": "A simple card"
  }
...
}

// Account Linking Card
{
  ...
  "card": {
    "type": "LinkAccount"
  }
  ...
}

// Permission Consent Card
{
  ...
  "card": {
    "type": "AskForPermissionsConsent",
    "permissions": [
      "alexa::profile:name:read"
    ]
  }
  ...
}
```

The Litexa `card` statement will send a Standard card. If you require one of the other three card types,
you can add them manually by [directly modifying the raw skill response](/book/backdoor.html#directly-modifying-the-response-object).

For more information about account linking, see the official documentation on [Alexa Account Linking](https://developer.amazon.com/docs/alexa-voice-service/authorize-companion-app.html).

For further information about permissions and the permission card, refer to the official documentation on
[Permissions Cards](https://developer.amazon.com/docs/custom-skills/request-customer-contact-information-for-use-in-your-skill.html).
