# Litexa HTML Web API Support

The Alexa Web API for Games allows you to use existing web technologies and tools to create
visually rich and interactive voice-controlled game experiences. You can build
for multimodal devices using HTML and web technologies like Canvas 2D, WebAudio, WebGL,
JavaScript, and CSS, starting with Echo Show devices and Fire TVs.

For more information, see the [Alexa developer portal documentation](https://developer.amazon.com/en-US/docs/alexa/web-api-for-games/understand-alexa-web-api-for-games.html)

There are two broad activities to creating a Web API capable skill: starting a web page and 
communicating with it. In this extension, new statements and an `HTML` API object 
give you tools that help tie these to your Litexa data. Note that the `HTML` API 
object is available as if it were in your inline JavaScript context, so you can refer
to it anywhere in the inline context, or from expressions in your Litexa code. 


## Installation

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



### `HTML` statement

This injects an `Alexa.Presentation.HTML.Start` directive into the current response, 
which causes a device to load the given URL. This statement will do nothing in the
absence of the HTML interface, so it's safe to let it silently fail.

The presence of this statement will also automatically add the `ALEXA_PRESENTATION_HTML`
to your skill manifest.

```coffeescript
launch
  HTML "app.html"
    timeout: 200
    initialData: @appData
    transformers: makeStartTransformers(@appData)
  -> idle
```

You can either use an absolute URL or a relative one, in which case Litexa will 
append the current assets root to the URL, letting you easily deploy your related
website from the Litexa assets folder.

Note, as with the directive, the timeout given is in seconds. 

Whatever you pass to initialData, you can expect to arrive in your web page as the 
data payload to successful initialization of the Alexa API object. [See the API documentation](https://html.games.alexa.a2z.com/modules/alexa.html) for details.

The `transformers` key expects an array value that will be added into the appropriate
location of the start directive.

For more information on what these values do, see [the directive documentation](https://developer.amazon.com/en-US/docs/alexa/web-api-for-games/alexa-presentation-html-interface.html#start-directive) 




### `HTML.isHTMLPresent()`

`HTML.isHTMLPresent` will return true at runtime if the skill is currently running on 
a device that supports the Alexa Web API. You can use this to write conditional 
code that branches on whether the user will see your HTML.

```coffeescript
launch
  if HTML.isHTMLPresent()
    HTML "app.html"
    -> startApp
  else
    say "Ah, I see your device doesn't support HTML. Let's try this instead."
    -> alternativeExperience
```

If at any time you need to shortcircuit HTML, you can call `HTML.setEnabled(false)`
to make `isHTMLPresent()` subsequently report false regardless of the device capabilities. 

Note that by default Litexa test runs as if it were running
on an Echo Show-like device, and will behave as if HTML is present. 
You can specify an Echo Dot like device instead by calling `litexa test --device=dot`

You can conditionally disable HTML in your Litexa tests by using the `DisableHTML` 
test statement. This lets you create a single test suite that tests both conditions,
as long as you test with a device that initially supports HTML.

```coffeescript
TEST "with HTML"
  DisableHTML false
  launch

TEST "without HTML"
  DisableHTML true
  launch
```


### `HTML.start(url, timeout, initialData, transformers)`

If you'd prefer to manipulate the directive directly, this function will
create an `Alexa.Presentation.HTML.Start` directive you can edit further. 
You may want to do  this if you need to add additional headers, for instance.

**IMPORTANT!** If you go this route, Litexa cannot automatically add 
the `ALEXA_PRESENTATION_HTML` to your skill manifest, so you'll need to 
add that manually.

You can use the directive as is:

```coffeescript
launch 
  directive HTML.start("hello.html")
  -> startApp
```

Or perhaps pass it through your own adaptor function:

```coffeescript
launch 
  directive myStartDirective()
  -> startApp
```

```javascript
// utils.js
function myStartDirective(){
  let directive = HTML.start("hello.html");
  directive.request.headers = {
    "Authorization" : "token"
  };
  return directive;
}
```


### `HTML.mark(name)` and `<mark name>`

The `HTML.mark()` function appends a formatted SSML tag to the current
say string.
The `<mark>` shorthand tag does the same thing inline in a say string.
When sent to your web page via a transformer, the mark will appear as an `ssml` 
tag type in the speechmarks list, at the appropriate timestamp.

```coffeescript
launch 
  HTML.mark("begin")
  say "Hello <mark wave> there player!"
```

This will produce the SSML: `<mark name='begin'/>Hello <mark name='wave'/> there player!`. 
When rendered through a transformer, you'll find the first mark at the 
start of the speechmark, and the second one following the last 
viseme for the word "Hello". Both will take the form `{ type: "ssml", value: "wave" }`, 
substituting each's respective names for the value property, and also
include with the usual `start`, `end`, and `time` speechmark properties.


### Events

To handle data that is sent from your web page, add a `when` listener for the
`Alexa.Presentation.HTML.Message` event in an appropriate state. Note you can
add it to the `global` state to handle any incoming message irrespective of
the current skill state.

```coffeescript
waitForTransmission
  when Alexa.Presentation.HTML.Message
    say "I received a message from the web page!"
    switch $request.message # payload from web page
      ...
```



## Tips

### Working with both speaker only devices and devices with screens

If you're interested in trying out transformers in your directives,
but want to maintain a skill that can switch between an HTML device
and a speaker only device, try using the usual Litexa `say` statements,
then write a [post processor](http://litexa.com/reference/backdoor.html#modifying-the-alexa-response-object)
to conditionally move your outputSpeech into a directive instead.
