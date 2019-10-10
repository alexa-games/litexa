# Gadgets: Custom Interfaces

[Custom Interfaces](https://developer.amazon.com/blogs/alexa/post/ca2cfbfb-37a2-49de-840c-f06f6ad8b74d/introducing-custom-interfaces-enabling-developers-to-build-dynamic-gadgets-games-and-smart-toys-with-alexa)
can be defined by [Alexa Gadget](https://developer.amazon.com/alexa/alexa-gadgets)s, for customizable
interactions with Alexa skills. For handling Custom Interfaces on the skill-side, the `@litexa/gadgets`
extension provides some shorthand syntax for:

1. managing custom event handlers
2. handling custom events, and
3. sending custom directives.

:::tip CUSTOM_INTERFACE
`@litexa/gadgets` also adds the required interface to the skill manifest, when needed.
:::

## Installation

The `@litexa/gadgets` module can be installed globally, which makes it available to any of your Litexa projects:

```bash
npm install -g @litexa/gadgets
```

If you alternatively prefer installing the extension locally inside your Litexa project for the sake of
tracking the dependency, just run the following inside of your Litexa project directory:

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

## Custom Event Handlers

Once a gadget has been configured to support Custom Interfaces (see
[How To Define and Use A Custom Interface on Your Gadget](https://developer.amazon.com/docs/alexa-gadgets-toolkit/custom-interface.html#how-to-define-and-use-a-custom-interface-on-your-gadget)), an Alexa skill
can start listening for events from the gadget by initializing a custom event handler.

This can be done by calling `startCustomEventHandler` on an expression which sources the desired handler data:

```js
function myEventHandlerData() {
  return {
    eventFilter: {
      filterExpression: { // only accept events that satisfy this expression
        and: [
          // namespace should be the name of interface defined by the gadget
          { "==": [{ "var": "header.namespace" }, "Custom.MyGadget"] }
          // name should be one of the event names supported by the gadget
          { "==": [{ "var": "header.name" }, "SupportedEventName"] }
        ]
      },
      filterMatchAction: "SEND_AND_TERMINATE" // stop handler after first event
    },
    expiration: {
      durationInMilliseconds: 60000, // lifetime of handler, unless stopped
      expirationPayload: { // payload to be sent to skill when this handler expires
        data: "Some data to be sent to skill upon handler expiration."
      }
    }
  }
}
```

```coffeescript
# someFile.litexa
someState
  startCustomEventHandler myEventHandlerData()
```

:::tip startCustomEventHandler will:

* add a handler `token` (unless one was specified)
* create a `CustomInterfaceController.StartEventHandler` directive and attach it to the pending skill response
* persist the handler token in memory (`@__lastCustomEventHandlerToken`), for validation of received events
* start ignoring any previously started event handler for the same namespace, if there is one that hasn't expired
:::

The last started event handler can be halted with `stopCustomEventHandler`:

```coffeescript
# someFile.litexa
someState
  stopCustomEventHandler
```

:::tip stopCustomEventHandler behavior:

* if a custom event handler was started and hasn't expired, a `CustomInterfaceController.StopEventHandler`
directive is created (specifying the last started handler's token) and attached to the pending skill response
:::

## Custom Interface Events

Once a skill has an active custom event handler, it can start receiving either of two events:

1. A `CustomInterfaceController.EventsReceived` event, when an event sent by the gadget matched the last started event
handler's `filterExpression`.
2. A `CustomInterfaceController.Expired` event, when an active event handler expired.

### .EventsReceived

An `EventsReceived` event request will contain an array of events that were sent by the gadget, where the request
would look something like this:

```js
{
  request: {
    type: "CustomInterfaceController.EventsReceived",
    requestId: /* ... */,
    timestamp: /* ... */,
    token: /* token of active event handler */,
    events: [ // event that passed the filterExpression
      {
        header: {
          namespace: "Custom.MyGadget",
          name: "SupportedEventName"
        },
        endpoint: {
          endpointId: "amzn1.ask.endpoint.someId"
        },
        payload: {
          /* arbitrary payload sent by the gadget */
        }
      }
    ]
  }
}
```

Such events can be handled in a Litexa skill as follows:

```coffeescript
  when CustomInterfaceController.EventsReceived "Custom.MyGadget"
    # this handler will only trigger if
    # 1) there's an active custom event handler for the indicated namespace
    # 2) the active custom event handler's token matched the event's

    # $event = saved event from request.events that triggered the handler
    say "looks like your gadget color is $event.payload.color"
    if $event.payload.color == "blue"
      say "Let's talk about water."
      -> talkAboutWater
    else if $event.payload.color == "red"
      say "Let's talk about fire."
      -> talkAboutFire

  when CustomInterfaceController.EventsReceived "Custom.AnotherGadget"
    # could handle multiple gadgets, if we started an event handler for each
```

### .Expired

An `Expired` event is received when an active event handler expires:

```js
{
  request: {
    type: "CustomInterfaceController.Expired",
    requestId: /* ... */,
    timestamp: /* ... */,
    expirationPayload: { /* defined during event handler start */ },
    token: /* token of expired handler */
  }
}
```

This can be handled in Litexa as follows:

```coffeescript
  when CustomInterfaceController.Expired
    # @__lastCustomEventHandlerToken = the last started handler's token
    if $request.token == @__lastCustomEventHandlerToken
      # last started handler expired -> handle it somehow
      say "Uh oh. Looks like our handler expired."
    else
      # an older handler expired, we don't care -> just keep listening for events
      LISTEN events
```

## Custom Interface Directives

Finally, a skill can use `CustomInterfaceController.SendDirective`s to send messages to the gadget. To do so,
the skill must first discover the gadgets connected to the user's device in order to detect the "endpoint ID".
For details on how to do so, refer to [Querying Available Gadgets](https://developer.amazon.com/docs/alexa-gadgets-toolkit/send-gadget-custom-directive-from-skill.html#call-endpoint-enumeration-api).

Once the endpoint ID is known, the skill can send a custom directive to that endpoint as follows:

```js
function buildCustomDirective() {
  return {
    type: 'CustomInterfaceController.SendDirective',
    header: {
      // some directive name that was whitelisted by the gadget
      name: 'SupportedDirectiveName',
      // same as for event handlers, name of interface defined by the gadget
      namespace: 'Custom.MyGadget'
    },
    endpoint: {
      endpointId: "amzn1.ask.endpoint.someId"
    },
    payload: { /* any data to be sent to gadget */ }
  };
}
```

```coffeescript
# someFile.litexa
someState
  directive buildCustomDirective()
```

## Relevant Resources

For more information, please refer to the official [Custom Interfaces](https://developer.amazon.com/blogs/alexa/post/ca2cfbfb-37a2-49de-840c-f06f6ad8b74dintroducing-custom-interfaces-enabling-developers-to-build-dynamic-gadgets-games-and-smart-toys-with-alexa)
documentation:

* [How To Define and Use A Custom Interface on Your Gadget](https://developer.amazon.com/docs/alexa-gadgets-toolkit/custom-interface.html#how-to-define-and-use-a-custom-interface-on-your-gadget)
* [Query Available Gadgets](https://developer.amazon.com/docs/alexa-gadgets-toolkit/send-gadget-custom-directive-from-skill.html#call-endpoint-enumeration-api)
* [Receive a Custom Event from a Gadget](https://developer.amazon.com/docs/alexa-gadgets-toolkit/receive-custom-event-from-gadget.html)
* [Send a Custom Directive to a Gadget](https://developer.amazon.com/docs/alexa-gadgets-toolkit/send-gadget-custom-directive-from-skill.html)
