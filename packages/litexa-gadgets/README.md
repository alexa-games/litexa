# Litexa Input Handler Support

This module adds support for both the [Game Engine
  Interface](https://developer.amazon.com/docs/gadget-skills/gameengine-interface-reference.html),
  and [Gadget Controller Interface](
  https://developer.amazon.com/docs/gadget-skills/gadgetcontroller-interface-reference.html),
  which make up the Alexa Gadgets Skill API. See [Alexa
  Gadgets](https://developer.amazon.com/docs/gadget-skills/understand-gadgets-skill-api.html)
  for more information.

The module `@litexa/gadgets` supports easily sending
and validating Input Handler and GadgetController.SetLight
directives, and handling GameEngine.InputHandlerEvents. It
adds new syntax for Input Handlers. Please find the
information on how to install and use this module below.

**NOTE:** When installed, the `@litexa/gadgets` will
validate any Input Handler and GadgetController.SetLight
directives added to a response, even if the directive wasn't
built using the module's new statements.

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

## Game Engine Interface

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

Event routing support is added for the
`GameEngine.InputHandlerEvent` request directly, with the
`$request` variable containing the full request object.

Events are automatically filtered by the last valid
`originatingRequestId`, with expired events (those generated
for any prior startInputHandler) being discarded silently.

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
loop over the events key to catch them
all:

```coffeescript
    when GameEngine.InputHandlerEvent
      for event in $request.events
        local result = processEvent(event)
```

Alternatively, you could switch over
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

In cases where both forms are used in the same state, the
general handler will be invoked first, followed by the
filtered version.

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

## Gadget Controller Interface

### Usage

There are no new statements for the Gadget Controller
Interface. However, use of the GadgetController.SetLight
directive often pairs with Input Handler directives. For
example, you may want the Echo Buttons to light up in a
sequence for the user to memorize as part of a game.

To add a GadgetController.SetLight directive in a
response, use the directive
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
