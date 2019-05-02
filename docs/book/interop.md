# JavaScript Interoperation

Some code is just better written in JavaScript (or a handy
language that compiles into JavaScript!); algorithmically
complex code or code that depends heavily on other JavaScript
code is usually a good candidate.
In any case, thinking of Litexa as your input/output layer
and JavaScript as your "business code" usually serves a larger
project very well.

Litexa supports calling functions and using values directly from
a special JavaScript context called the *inline context*. Code
from this context is referred to as *inline code*.

## Compilation and the Inline Scope

Let's take a moment to look at the compilation process in Litexa.

All of the code in your `litexa` directory is intended to produce
an output directory that will be run on your server as your
skill's endpoint. That endpoint will boil down to a single
function in a file named index.js that takes an Alexa request
JSON object and returns an Alexa response one.

1. All of your `.litexa` code files will be converted into various
chunks of JavaScript code and added to that index.js.

1. All of the `.js` and `.coffee` files found in that directory
will *also* be copied directly into the index.js file, automatically,
without any additional wrapping.

1. All of the `.json` files in the directory will be read, parsed,
and added to a JavaScript object called [jsonFiles](/reference/#jsonfiles),
using their filename as the key.

This means that the contents of all the code and data files in
your `litexa` directory will sit in the same context, be visible
to each other, and more importantly be visible to any Litexa code.
This is the *Litexa inline context*.

If you have a `node_modules` directory, created by any means, inside
your `litexa` directory, then that folder will be included in
your code deployment, and any code from your inline context can
use the normal JavaScript `require` statement to pull it in.

In general it's best to think of the inline context as a place to
write short to medium length helper functions and data structures,
as well as glue code to require and name elements from larger
code packages, that you want to use from Litexa code.

## JavaScript Variables and Functions

Any JavaScript symbols in your inline context are visible from
your Litexa code. Values are usable directly, as if they
were Litexa variables. This includes object and array values.

```javascript
// litexa/main.js
let currentYear = 2019
let passengerSounds = {
  dog: "woof",
  cat: "meow",
  mouse: "squeak"
}
let weights = [
  5, 3
]
```

```coffeescript
# main.litexa
launch
  say "This is the year {currentYear}. Cats say {passengerSounds.cat}."
  say "Total passenger weight is {weights[0] + weights[1]}."
```

Likewise functions can be called directly, with parentheses
syntax. Arguments to function calls can be any expression,
and so can include Litexa variables.

```javascript
function formatName(name) {
  return `the most honorable ${name}`;
}
```

```coffeescript
  when "my name is $name"
    with $name = AMAZON.US_FIRST_NAME

    say "Nice to meet you, {formatName($name)}."
```

Functions called from Litexa may need to do some asynchronous
work, like retrieve data from another web service. Litexa
calls to JavaScript are always awaited, so async JavaScript
functions will naturally stop the state machine until they're
ready to continue.

```javascript
async function getPrice(thing){
  let code = await codingService.getCodeForThing(thing);
  return await pricingService.getPriceForCode(code);
}
```

```coffeescript
  when "how much is a $thing"
    with $thing = slotbuilder.build.js:thingList

    say "The price of a $thing is {getPrice($thing)}."
```

## Typed Persistent Variables

For more complex variables, it can be useful to write class
like objects in JavaScript to encapsulate behavior.

For persistent variables, without any interventions, the
prototypes for these objects would be lost when stored
as JSON objects between requests.

Litexa supports reattaching the prototype on subsequent
requests by using the global `define` statement. Variables
defined this way will always exist, and will be constructed
once and only once ever, before their very first use.

There are two possible mechanisms to use: *classes* and
*constructors*.

In the class method, you can directly refer to any JavaScript
class or newable value in your inline context as the variable
type.

```javascript
// litexa/myClass.js
class MyClass {
  constructor() {
    this.noun = "person";
    console.log("MyClass constructed");
  }
  greeting() {
    return `Hello, ${this.noun}`;
  }
}
```

```coffeescript
# litexa/main.litexa
define @thing as MyClass

launch
  # @thing always exists, and we can call methods on it
  @thing.noun = "human"
  say "@thing.greeting()"
  # Alexa says "Hello, human"
```

The constructor method provides more flexibility in that
you separately control the mechanisms for initializing and
constructing the object the persistent variable will
represent.

To create a constructor type, you must create an object
in your inline scope that has the functions `Initialize`
and `Prepare`.

`Initialize` will be called once, and only
once, to create a JSON object that represents the
database stored value. At each time the variable is used
in Litexa code, the `Prepare` function will be called to
attach a prototype or even replace the object that will
be visible to Litexa code. Note: the object given to
`Prepare` will remain the object that is persisted to
the database, irrespective of what value `Prepare` returns.

In the following example, a constructor is specified that
wraps access to a name object. When loaded, it goes and
fetches some extra data from a mock service that is
combined ephemerally with the database data.

```javascript
var FullNamePrototype = {
  async fullName(prefix) {
    await this.ensureCache();
    return prefix + " " + this.cache.title + " " + this.data.first + " " + this.data.family
  },
  async ensureCache() {
    var wrapper = this;
    if (wrapper.cache.loaded) {
      return;
    }
    await new Promise((resolve, reject) => {
      wrapper.cache.title = 'Ms.';
      wrapper.cache.loaded = true;
      setTimeout(resolve, 200);
    });
  },
  async saveLoaded() {
    await this.ensureCache();
    this.data.loaded = this.cache.loaded;
  }
}

var FullName = {
  Initialize() {
    return {
      first: "Lana",
      family: "Wrapsdottir"
    }
  },
  Prepare(obj) {
    var wrapper = Object.create(FullNamePrototype);
    wrapper.data = obj;
    wrapper.cache = {}
    return wrapper;
  }
}
```

We can then use the constructor in our Litexa code.

```coffeescript
define @name as FullName

launch
  @name.first = "Jane"
  say "Hello, @name.fullName("delightful")"
  # Alexa says "Hello, delightful Ms. Jane Wrapsdottir"
```
