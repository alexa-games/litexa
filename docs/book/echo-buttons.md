# Echo Buttons

An [Echo
Button](https://www.amazon.com/Echo-Buttons-Pack-gaming-companion/dp/B072C4KCQH)
is an [Alexa Gadget](https://developer.amazon.com/alexa/alexa-gadgets),
which is an accessory that pairs to compatible Alexa-enabled
devices via Bluetooth. The accessory can be used in
conjunction with Alexa skills to enhance skill experiences.

For a skill to interact with Echo Buttons (and potentially
other Alexa Gadgets), it must use the [Gadgets Skill API](
  https://developer.amazon.com/alexa/alexa-gadgets/gadgets-skill-api).
The Gadgets Skill API is comprised of two interfaces:

* [Game Engine Interface](
  https://developer.amazon.com/docs/gadget-skills/gameengine-interface-reference.html)
* [Gadget Controller Interface](
  https://developer.amazon.com/docs/gadget-skills/gadgetcontroller-interface-reference.html)

Litexa provides an extension for both interfaces
in the Gadgets Skill API.

In this chapter, you will learn:

<span style="color:#00caff">&#10004;</span>  how to use the `@litexa/gadgets` extension<br/>
<span style="color:#00caff">&#10004;</span>  some best practices in designing for voice + Echo Buttons<br/>
<span style="color:#00caff">&#10004;</span>  how the above points apply to an existing, live skill<br/>

## The Gadgets Extension Overview

### Game Engine Interface

The `@litexa/gadgets` extension provides Litexa syntax
and support for the Game Engine Interface. This interface is
useful for sending *Input Handler* directives to control
what events the skill will receive from button input.

An Input Handler is a command to filter events to only
receive events your skill will care about. Filtering events
properly is key to writing a robust skill for the following
reasons:

1. Each button press creates 2 events - the button being
   pressed and released. Subscribing to all of these events
   may flood your skill with events it might not care about,
   and cause unnecessary invocations of your skill's
   endpoint. This is important to consider since if you're
   using the `@litexa/deploy-aws` module, your skill's
   endpoint is AWS Lambda. AWS Lambda calculates its cost by
   how many times it runs your skill. If you have users
   spamming button presses in your skill, that cost will add
   up quickly.

2. Taking in more events than necessary may also cause your
   skill's runtime performance to suffer because events are
   received asynchronously, but may be handled as if they
   were received sequentially. If you are using
   `@litexa/deploy-aws`, this is definitely the case.

The module `@litexa/gadgets` supports easily sending
and validating Input Handler directives, and handling
GameEngine.InputHandlerEvents. Please find the information
on how to install and use this module below.

:::tip Directive Validation
When installed, the `@litexa/gadgets` will validate any Input
Handler directives added to a response, even if the directive
wasn't built using the module's new statements.
:::

### Gadget Controller Interface

The `@litexa/gadgets` extension provides validation for
GadgetController.SetLight directives added to a response only; it does not add
new Litexa statements.

## Installation

The module can be installed globally, which makes it
available to any of your Litexa projects:

```bash
npm install -g @litexa/gadgets
```

If you alternatively prefer installing the extension locally
inside your Litexa project for the sake of tracking the
dependency, just run the following inside of your Litexa
project directory root:

```bash
npm install --save @litexa/gadgets
```

This should result in the following directory structure:

```stdout
project_dir
├── litexa
└── node_modules
    └── @litexa
        └── gadgets
```

## Extension: Game Engine Interface

### New Statements

When installed, the module adds a few new statements to
Litexa's syntax.

The `startInputHandler` statement adds support for declaring
an Input Handler, and expects an inline function call that
returns a single directive as an argument.

```coffeescript
    startInputHandler createHandler()
```

The `createHandler` function might look something like:

```javascript
createHandler = function() {
  var inputHandler = {
    type: "GameEngine.StartInputHandler",
    timeout: 60000,
    ...
  };
  return inputHandler;
};
```

Litexa will automatically save the `originatingRequestId`
attached to this Input Handler, which is a requirement for
validating that your skill handles only the events it asked
for.

The `stopInputHandler` statement creates the appropriate
directive and automatically inserts the saved
`originatingRequestId` of the last Input Handler started by
the skill. It takes no arguments.

```coffeescript
    stopInputHandler
```

:::tip Standalone stopInputHandler directives are ok
It is okay to put a `stopInputHandler` anywhere you might
need to, even if there is not a specific Input Handler it
might apply to. This is useful in handlers suited for global
use (e.g. `AMAZON.StartOverIntent` to start over at any
point in a game - you don't want the Input Handler's timeout
event to interrupt her speech) and other cases where
multiple interaction flows might go to a common state.

If there is no active Input Handler, Litexa will ignore the
`stopInputHandler` directive and instead simply log a
warning.
:::

Event routing support is added for the
`GameEngine.InputHandlerEvent` request directly, with the
`$request` variable containing the full request object.

:::warning Automatic filtering of events by originatingRequestId
Events are automatically filtered by the last valid
`originatingRequestId`, with expired events (those generated
for any prior startInputHandler) being discarded silently.
:::

Event handler syntax and behavior follow those of intent
handlers. There are two forms of event handlers, listed
below.

#### General Handler

You can write an event handler as below, which will cause
Litexa to route all Input Handler events to it while in that
state:

```coffeescript
    when GameEngine.InputHandlerEvent
      local result = processInputEvents($request.events)
```

Each request may include multiple events, so you can
[loop](/reference/#for) over the events key to catch them
all:

```coffeescript
    when GameEngine.InputHandlerEvent
      for event in $request.events
        local result = processEvent(event)
```

Alternatively, you could [switch](/reference/#switch) over
the names and react to event names directly:

```coffeescript
    when GameEngine.InputHandlerEvent
      for event in $request.events
        switch event.name
          == "red" then
            say "red was pressed!"
          == "blue" then
            say "blue was pressed!"
          else
            say "I didn't recognize event {event.name}"
        local result = processEvent(event)
```

#### Filtered Handler

An alternate form of the intent handler that filters for
event names is also available. In this case, the code *will*
be executed repeatedly, if multiple of the same event are
received. Inside these named intent handlers, the `$event`
slot variable will contain the current Input Handler event.
The following example's behavior is identical to the switch
statement example above.

```coffeescript
    when GameEngine.InputHandlerEvent "red"
      say "red was pressed"
      local result = processEvent($event)

    when GameEngine.InputHandlerEvent "blue"
      say "blue was pressed"
      local result = processEvent($event)
```

:::tip Mixing handlers in the same state
In cases where both forms are used in the same state, the
general handler will be invoked first, followed by the
filtered version.
:::

### Testing Support

To test incoming Input Handler events, you can use the new
`inputHandlerEvent` statement to generate an event matching
the name of an event you've programmed into your
`startInputHandler` directives.

```coffeescript
    TEST "pressing buttons"
      launch
      inputHandlerEvent "button 1 pressed"
```

If you need more information in your test, e.g. a sequence
of simulated button events in the history, then you can
write a JSON file with just the contents of the `events` key
in the [skill
request](
  https://developer.amazon.com/docs/gadget-skills/receive-echo-button-events.html#receive),
and refer to that
in the test instead.

```coffeescript
    TEST "pressing buttons"
      launch
      inputHandlerEvent quickPress.json
```

The `quickPress.json` file contents might look like:

```json
    [
      {
        "name": "button pressed",
        "inputEvents": [
          {
            "gadgetId": "agadget",
            "timestamp": "2017-08-18T01:32:40.027Z",
            "action": "down",
            "color": "FF0000"
          },
          {
            "gadgetId": "agadget",
            "timestamp": "2017-08-18T01:32:41.050Z",
            "action": "up",
            "color": "FF0000"
          }
        ]
      }
    ]
```

:::warning Test events do not test Input Handler logic
Test events in your Litexa tests are *fully disconnected*
from your actual Input Handler. This means your Litexa
tests cannot validate whether or not your Input Handler
actually behaves as you expect it to. It can only test the
skill behavior of receiving the expected InputHandlerEvent.

To test your Input Handler functionality, you will need to
use a real Alexa-enabled device and Echo Buttons or the ASK
Developer Console skill simulator.
:::

:::warning Skill simulator timeouts on ASK Developer Console
As of March 2019, the ASK Developer Console skill simulator
does not correctly display the effects of timeout events to
the simulator, even though your skill backend will receive
them. It is recommended to look at skill logs when testing
your Input Handler's timeout event.
:::

## Extension: Gadget Controller Interface

### Usage

There are no new statements for the Gadget Controller
Interface. However, use of the GadgetController.SetLight
directive often pairs with Input Handler directives. For
example, you may want the Echo Buttons to light up in a
sequence for the user to memorize as part of a game.

To add a GadgetController.SetLight directive in a
response, use the [directive](/reference/#directive)
keyword:

```coffeescript
gameStart
  say "Press the buttons when they are blue."
  directive animateButtonsForGame()
```

and `animateButtonsForGame()` would look something like
this:

```javascript
animateButtonsForGame() {
  return [
    {
      type: "GadgetController.SetLight",
      parameters: {...},
      ...
    }
  ]
}
```

### Testing Support

In your Litexa tests, the directives will show up as seen
below, as part of the simulation output:

```coffeescript
84.  ❢    COUNT_BUTTONS   $count=5 @ 3:02:10 PM
     ◖----------------◗ "<!ouch,> I can't deal with more than four buttons right now. Before we start: Trickster, how many buttons do you want to use?" ... "Tell me Trickster, how many buttons should I look for?"
                          [DIRECTIVE 54] GadgetController.SetLight
```

As for the actual content, you can write tests in your code
files, and look at the directive JSON in the skill response
in `.test/output.json`.

### Skill Manifest Addition

If you use the Gadget Controller interface, you will need to
include `GADGET_CONTROLLER` in your `skill.*` file, to
officially tell Alexa that your skill is using it.

```json
{
  "manifest": {
    "apis": {
      "custom": {
        "interfaces": [
          {
            "type": "GADGET_CONTROLLER"
          }
          ... // other interfaces
        ]
  ...
}
```

## Intent Handling Requirements

When using either interface of the Gadgets Skill API, the
`AMAZON.HelpIntent` and `AMAZON.StopIntent` must be handled
by the skill (i.e. included in at least one `when`
listener). Not doing so will result in an error during
deployment.

This can be done via state-specific handlers, or a `global`
handler:

```coffeescript
waitForAnswer
  when AMAZON.HelpIntent
    say "Please answer the question. You can say, I don't know, to pass."

global
  when AMAZON.StopIntent
    say "Goodbye for now."
```

## Best Design Practices

:::tip Best Practice for writing the Input Handler
You should use the Input Handler as a middleman to offload
and aggregate some of the button event calls that would have
otherwise been sent to your skill to handle. It is valuable
to experiment and construct an Input Handler for your needs
that minimally produces only the events you need, instead of
conducting equivalent filtering logic and receiving all
events. The Input Handler definition may be daunting to
learn, but it will be well worth it in the long run.

A suggestion for experimentation is to create a new skill or
temporarily move the experimental Input Handler to the front
of your skill flow in order for you to iterate quickly.
:::

The Alexa Games team has learned a lot about building skills
for a combination of voice *and* Echo Button interactions.
Some of the good practices and observations we'd like to
share are:

1. **Acknowledge user input.** This applies to both voice
   and buttons. For voice, it can be a simple phrase like
   "Okay" or "Great". For example:

   ```coffeescript
   startRollCall
     ...
     say "Before we start: Trickster, how many buttons do you want to use?"
     ...

   rollCallCount
     when COUNT_BUTTONS
       ...
       say "Great! Now, please press each of those $count buttons in turn."
       ...
   ```

   For buttons, animating a button on press is sufficient. In
   skills that require a buttons roll call step though, it is
   recommended to acknowledge the last button event you are
   expecting, by adding that animation to the front of your
   skill's next response.

2. **Keep the microphone closed when expecting button
   input** by using [LISTEN or LISTEN events](
   /reference/#listen). As an addendum, **fill silence when
   expecting input**. Otherwise, this will cause confusion
   to your user on whether or not the skill session is still
   open. A good idea is to add a background track to the end
   of Alexa's speech, and, if expecting voice input, to also
   advise the user to say the wake word before speaking
   their utterance.

3. **Design for voice first.** Depending on your game,
   people aren't always looking at their Echo Buttons. Audio
   cues are preferable to visual cues. If you need users to
   look at their Echo Buttons, it may be useful to have
   Alexa explicitly state that.

4. **Communicate expression in your animations.** You can
   add a lot of variation to your button animations. For
   example, in Button Monte, we use a lively pulsing to
   indicate that the user selected the correct button.
   Conversely, you may use a slow pulsing or color-changing
   animation to indicate that your buttons are active, but
   idle in the skill.

5. **Design for color-blindness.** If differentiating
   between colors is integral to your skill design, it is
   recommended to avoid color combinations that may not be
   color-blind friendly. You can also use alternative
   differentiators between animations that don't rely on
   color, like varying intensities and animation pulsing
   rates.

For more on best practices, see [Best Practices for Echo
Button Skills](
  https://developer.amazon.com/docs/gadget-skills/best-practices-for-echo-button-skills.html).

## Case Study: Button Monte

[Button Monte](
  https://www.amazon.com/Amazon-Button-Monte/dp/B077T2G3ZW)
is one of the first Echo Button skills released. It is an
Echo Button version of the classic shell game. Its game
design relies on Echo Buttons being physically mobile.
This section will walk through the design and usage of the
Input Handlers and animations.

### Roll Call

The first time the skill uses an Input Handler directive is
in roll call. Here's what it looks like, for a four button game:

```json
{
  "type": "GameEngine.StartInputHandler",
  "timeout": 60000,
  "proxies": [
    "btn0",
    "btn1",
    "btn2",
    "btn3"
  ],
  "maximumHistoryLength": 100,
  "recognizers": {
    "button pressed": {
      "type": "match",
      "fuzzy": false,
      "anchor": "end",
      "pattern": [
        {
          "gadgetIds": [
            "btn0",
            "btn1",
            "btn2",
            "btn3"
          ],
          "action": "down"
        }
      ]
    },
    "all pressed": {
      "type": "match",
      "fuzzy": true,
      "anchor": "start",
      "pattern": [
        {
          "gadgetIds": [
            "btn0"
          ],
          "action": "down"
        },
        {
          "gadgetIds": [
            "btn1"
          ],
          "action": "down"
        },
        {
          "gadgetIds": [
            "btn2"
          ],
          "action": "down"
        },
        {
          "gadgetIds": [
            "btn3"
          ],
          "action": "down"
        }
      ]
    }
  },
  "events": {
    "NewButton": {
      "meets": [
        "button pressed"
      ],
      "fails": [
        "all pressed"
      ],
      "reports": "history",
      "maximumInvocations": 24,
      "shouldEndInputHandler": false
    },
    "Timedout": {
      "meets": [
        "timed out"
      ],
      "reports": "history",
      "shouldEndInputHandler": true
    },
    "Finished": {
      "meets": [
        "all pressed"
      ],
      "reports": "matches",
      "shouldEndInputHandler": true
    }
  }
}
```

We send this directive during the `rollCallCount` state,
after we receive a valid number for the number of buttons in
play. Here is how we handle its events in Litexa code:

@[code lang=coffeescript transclude={106-158}](@/samples/button-monte-sample/litexa/main.litexa)

Here's how the two code fragments above work together. The
skill defines an Input Handler with 3 unique
events. In Litexa, the state handles each event using the
filtered handler syntax. Here is how the
`startInputHandler`'s events are defined and handled:

* The directive defines a "NewButton" event that will happen
  *n-1* times, with *n* being the number of buttons specified by
  the user. The "fails" condition guarantees that both this
  event and the "Finished" event cannot trigger at the same
  time. The skill handles each of these events by recognizing
  and storing the new button's gadgetId, and also
  acknowledging its registration with audio output.
* The directive defines a "Finished" event that fires only
  when the desired number of unique buttons are pressed. It
  goes through the same registration steps as the
  "NewButton" event, but then also transitions to the start
  of the game.
* The directive defines a "Timedout" event triggered from
  the [built-in `timed out` recognizer](
  https://developer.amazon.com/docs/custom-skills/game-engine-interface-reference.html#timedoutrecognizer).
  It handles this by acknowledging how many unique buttons
  it registered, exiting the skill session, and explaining
  where to troubleshoot Echo Button connectivity in the
  Alexa app.

:::tip An alternate roll call Input Handler
In the code sample, you will find an alternative roll call
Input Handler, which you can use instead of the one
programmed in. Search for `alternativeRollCallDirective` in
`main.coffee` to find it. The comments above it explain the
differences and give an explanation of how to write its
Litexa event handlers.
:::

### Gameplay

The skill's gameplay relies on the animation and colors of
the Echo Button animations. The Gadget Controller directives
sent in the skill response will designate a "shell" button
and highlight it in animation for the Watcher. Then, all
buttons will change to the same color, and the Trickster
shuffles the buttons at this time. Then, all buttons will
turn green simultaneounsly, rendering them eligible to
trigger either the "win" or "lose" Input Handler directive's
events, with the specific event based on the gadgetId of the
"shell" button.

Rather than showing the full directive here (it's a long
formatted JSON object), here's the general sequence of
colors per button.

* the "shell" button: pulse red &#8594; orange &#8594; green
* all other buttons: blue &#8594; orange &#8594; green

:::tip Aggregating animations across Litexa states
  In Litexa code, it is not immediately obvious on which
  skill responses will send which animations, because there
  is no persistent animation state across Litexa states.
  Therefore, you will need to find your own way of saving
  relevant information across states for animations, and
  factor that into the skill response's animation directive.

  In the Button Monte sample, we want to visually acknowledge the
  last button pressed in roll call before we start the game.
  We do this by saving a database variable
  `@thisGameDidRollCall`, then passing it in as an argument
  to the `startGame()` function, which builds the game's
  directives. The function will use that variable to
  determine whether or not to override the initial few
  animation sequence elements with the roll call animation
  color.
  
  So the above animation sequence for the button that was
  pressed in roll call for that game will be one of:

* the "shell" button: orange &#8594; pulse red &#8594; orange &#8594; green
* all other buttons: orange &#8594; blue &#8594; orange &#8594; green
:::

The skill gameplay's Input Handler is defined such that we
look at the named event that came back, instead of further
parsing the event's `inputEvents` field for either color or
gadgetId. In a four button game, it looks like:

```json
{
  "type": "GameEngine.StartInputHandler",
  "timeout": 31860,
  "maximumHistoryLength": 100,
  "recognizers": {
    "winner": {
      "type": "match",
      "fuzzy": true,
      "anchor": "start",
      "pattern": [
        {
          "action": "down",
          "colors": [
            "00FE00"
          ],
          "gadgetIds": [
            "gadgetId3"
          ]
        }
      ]
    },
    "losers": {
      "type": "match",
      "fuzzy": true,
      "pattern": [
        {
          "action": "down",
          "colors": [
            "00FE00"
          ],
          "gadgetIds": [
            "gadgetId1",
            "gadgetId2",
            "gadgetId4"
          ]
        }
      ]
    }
  },
  "events": {
    "win": {
      "meets": [
        "winner"
      ],
      "reports": "matches",
      "shouldEndInputHandler": true
    },
    "lose": {
      "meets": [
        "losers"
      ],
      "reports": "matches",
      "shouldEndInputHandler": true
    },
    "timeout": {
      "meets": [
        "timed out"
      ],
      "reports": "history",
      "shouldEndInputHandler": true
    }
  }
}
```

The skill uses the same event handler syntax as roll call
for handling this Input Handler's events:

@[code lang=coffeescript transclude={201-215}](@/samples/button-monte-sample/litexa/main.litexa)

The Input Handler and event handlers are straightforward
here.

* The "win" event is triggered by the "winner" recognizer,
  which requires the conditions of the shell button being pressed
  while it is green. In the example, the shell button is
  "gadgetId3". The skill responds to this event by declaring
  the Watcher as the winner.
* The "lose" event is triggered by the "losers" recognizer,
  which requires the conditions of any of the other buttons
  being pressed while it is green. The skill responds to
  this event by declaring the Trickster as the winner.
* The "timeout" event is the same as in the roll call input
  handler. The skill responds to this event by declaring
  the Trickster as the winner, as the result of the Watcher
  not pressing a button in time.
* The duration of the Input Handler is derived from the
  total duration of the accompanying animation directives.

## Resources

* [Gadgets Skill API overview](https://developer.amazon.com/docs/gadget-skills/understand-gadgets-skill-api.html)
* [Game Engine
  Interface](https://developer.amazon.com/docs/gadget-skills/gameengine-interface-reference.html)
* [Gadget Controller
  Interface](https://developer.amazon.com/docs/gadget-skills/gadgetcontroller-interface-reference.html)