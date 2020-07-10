# Variables and Expressions

Variables are a programming language's way of
naming and storing chunks of data.

When your skill is live, multiple users will show
up and interact with it simultaneously, and your
endpoint will need to handle interleaved requests
coming from all of them. So each request will need
to "pick up" from where that users is in your skill.

Aside from that, with longer form skills you'll
usually want to remember things about your users,
say where they are in a longer game so they don't
have to start from scratch.

Both of these needs inform Litexa's approach to
variable *scoping*, the lifespan and visibility
of variables, producing three distinct kinds
of variables: *local, request and persistent*.

Because some variables will need to survive past
the current request, and possibly even pick up on
a different machine all together, in the case that
your skill endpoint is load balanced, Litexa
differentiates between two kinds of variable
*storage* types: *memory, and database*.

## Storage types

*Memory storage* is ephemeral and exists only for the
duration of the skill code execution. These kinds
of variables can be initialized at any time before
or during the execution of skill code. For example,
request variables (explained below) can be populated
from an incoming skill request. When the skill sends
the response, the code is done executing and
therefore the variable will no longer exist.

*Database storage* variables persist their value across
each skill request and response. They can be
initialized at any time during the execution of skill
code, and will continue to exist for subsequent skill
executions. Litexa's backend also makes use of database
storage to keep track of the current skill state. There
is only one type of database storage variable, called
persistent variable.

Note: by default, Litexa is set up to create a new
database entry for each device that a user invokes
your skill from, protecting it from interference
should your skill be invoked at the same time on different
devices. To modify this, see the section below on
[Customizing the Litexa DB Key](#customizing-the-litexa-db-key).

## Value Types

Each variable in Litexa can store one of a number of
different kinds of values.

* Numbers, integer or floating point, e.g. `1, -8, or 15.4`
* Booleans, the values `true` or `false`
* Strings, double quoted, e.g. `"Hello"` and `"World"`

Additionally, Litexa variables can also host any
valid JavaScript value, including objects, arrays,
null, undefined, and even functions, with one caveat:
any variables with *database storage* must survive
conversion to and from JSON.

Strings in Litexa may span more than one line, letting
you break up longer strings as you see fit. In this
case, white space to the left of the second line will
be collapsed into a single space, and subsequent lines
will remove the same amount of whitespace.

In the next sample, a and b will contain the same strings.

```coffeescript
launch
  local a = "here's a string
    with a second,
    and third line"

  local b = "here's a string with a second, and third line"
```

## Variable Types

### Local Variables

The first kind of variable behaves much like
traditional variables in that they are *lexically
scoped*, meaning that their lifespan will align
with the block of code they sit in, and they will
be visible to any code inside that block.

Local variables must be declared before use, with
the `local` statement, and cannot be declared
again in the same scope, including in subordinate
blocks of code: Litexa does not allow *variable
shadowing.*

Local variables must also be initialized with a value.

```coffeescript
launch
  local counter = 0
  local name = "Jane"
  local flag = false
```

Local variables that are declared and used in a
single handler have memory storage. Local variables
can survive across more than one handler though,
when declared in the state's entry handler and then
referenced in any of the state's intent handlers or
the state's exit handler. In this case, they are
automatically promoted to database storage.

::: warning
Reentering a state will reset its "persistent"
local variables, since it will call the initialization
in the state's entry handler.
:::

In the next example:

1. The loops variable is declared and initialized to 0
in askForAction's entry handler.
2. While in askForAction, any help or unexpected intent
will increment loops by 1 in its handler.
3. In the handler for a valid action intent, a state
transition to takeAction is called. This triggers
askForAction's exit handler and reads out the loops value.

```coffeescript
askForAction
  local loops = 0
  say "What should we do?"

  when "let's $action"
    with $action = "jump", "run", "shoot"
    say "Alright, attempting $action"
    -> takeAction

  when AMAZON.HelpIntent
    loops = loops + 1
    say "Just tell me what you want to do."

  otherwise
    say "Yeah no, that's not going to work. What should we do?
      Maybe jump, run, or shoot?"
    loops = loops + 1

  if loops > 1
    say "Geez, that only took {loops} tries."
```

### Request Variables

Request variables live from the moment they are
declared until the end of the current request, that
is to say until the end of the next handler that
ends with a LISTEN or END statement. This means
they survive between states, and will always have
memory storage.

Request variable names must always begin with the
`$` character, and are declared and created on
their first assignment.

We've already come across several request variables
so far, in the form of slot values.

```coffeescript
askForName
  say "Hey, what's your name?"

  when "my name is $name"
    with $name = AMAZON.US_FIRST_NAME

    # the $name variable exists here
    say "Hello $name."
    -> flatterPlayer

flatterPlayer
  # because we came here directly from the other state
  # the request variable is still in scope
  say "$name is such a pretty name, don't you agree?"

  when AMAZON.YesIntent
    # as this intent happens in a different request,
    # the $name variable is no longer available
```

Request variables can be empty, that is to say they
might not have been assigned yet. In that case, they'll
contain a "falsy" value, meaning you can use an `if`
statement to choose behavior based on their existence.

In the following example, not all utterances contain
all slots, so in some cases the slot may not have a
value.

```coffeescript
askForAttack
  say "How should we attack?"

  when "attack the $enemy with the $weapon"
    or "attack the $enemy"
    or "use the $weapon"
    with $enemy = enemies.js:enemySlots
    with $weapon = weapons.js:weaponSlots

    if $enemy
      say "Attacking the $enemy."

    if $weapon
      say "Using the $weapon."
```

### Persistent Variables

Sometimes you need a variable to survive longer than
both local and request variables. Persistent variables
exist from the moment they are created until you decide
to destroy them.

:::warning
The project option [`useSessionAttributesForPersistentStore`](/book/deployment.html#switching-the-persistent-store-to-session-attributes-instead)
changes this promise by redirecting persistent storage
to Alexa session attributes instead. This means the variable
will only exist until the end of each skill session; every
new launch will begin with no persistent variables defined
at all.
:::

Persistent variable names always begin with the `@`
symbol and always have database storage, meaning they
must be able to survive being converted to and from
JSON.

As with request variables, persistent variables that
haven't been assigned to yet will have a falsy value,
and can be tested directly.

```coffeescript
launch
  if @name
    say "Welcome back, @name."
    -> playGame
  else
    say "Hello, stranger"
    -> askName

askName
  say "What's your name?"

  when "My name is $name"
    with $name = AMAZON.US_FIRST_NAME

    say "Nice to meet you, $name"
    # store the result permanently
    @name = $name
```

### DEPLOY Variables

DEPLOY variables are a type of memory storage variable that are references
to static properties of a `DEPLOY` object defined under a deployment
target. They are readable during compilation as well as runtime, and can
be used to manage target-specific skill behavior.

To define DEPLOY variables, add a `DEPLOY` object in your deployment targets
like so:

```javascript
const deploymentConfiguration = {
  name: 'cats-in-space',
  deployments: {
    development: {
      ... // other configuration
      DEPLOY: { // your DEPLOY variables go in this object
        DEBUG: true,
        MODE: 'practice'
      }
    },
    production: {
      ... // other configuration
      DEPLOY: {
        MODE: 'challenge'
      }
    },
    ...
```

These variables will then be available for use in your Litexa code with their
values dependent on which deployment target you specified in the litexa command
(`litexa test`, `litexa deploy`, etc.).

:::warning
The `DEPLOY` object should only be used for properties, not methods.
:::

DEPLOY variables can be useful when you want specific values in your builds for
testing. For example, you can bypass non-deterministic logic.

```coffeescript
announceCategory
  say "Your next category is,"
  if DEPLOY.DISABLE_RANDOM
    say "{getIncrementalCategory()}."
  else
    say "{getRandomCategory()}."
```


Here are some applications of DEPLOY variables:
* Something like a `DEBUG` flag can be used to turn on test-only intents in your skill. For example, you can use them in test skills to jump to another part of the skill as a
shortcut.
* Something like a `LOG_LEVEL` string can be used to set different logging levels.
* Something like a `VERSION` flag or string could allow deploying multiple similar skills that all use the same core skill logic.

DEPLOY variables are the only type of variable that can be used in [`when`
statements](/reference/#postfix-conditional) and [file exclusion statements](/reference/#exclude-file).

Otherwise, if you want to deploy multiple skills where most of their
logic is the same, you can keep them as one Litexa project with different
`DEPLOY` object configurations, thereby avoiding code duplication.

## Expressions

There are various places in Litexa syntax that accept
an *expression*, which is a chunk of code that produces
a resulting value.

The simplest expressions are just primitive values.
Here we see the right side of an assignment statement
taking a few of these expressions.

```coffeescript
  local a = 15
  local name = "Sue"
```

Expressions can contain operators that combine two values
into a new one. Litexa supports the following list of
arithmetic operators `-`, `+`, `*`, and `/`

```coffeescript
  local a = 5 + 10
  local b = 10 / 2
  local phrase = "Hello" + " " + "World"
```

You can also produce boolean values using a the set of
comparison operators `==`, `!=`, `>`, `>=`, `<`, `<=`,
`and` and `or`

```coffeescript
  local a = 5 > 3
  local b = name == "Bob" and age == 18
```

You can control the order that parts of an expression
evaluate in by using parentheses.

```coffeescript
  local a = ( 5 + 10 ) * 3
```

You can also include variable names in expressions to
use their values.

```coffeescript
  local a = 10
  local b = a + 5
  $count = 10
  local c = ( a * $count ) + b - 7
```

Calling a function that is available from a non-Litexa code file is also an expression.

```coffeescript
  local a = foo()
  local b = bar(a) + 7
  functionThatDoesNotExplicitlyReturn() # this is still an expression because it
                                        # will return undefined
```

### Static Expressions

Static expressions are expressions in which all parts of the expression can be
evaluated during compilation. If an expression contains any dynamic part, then
the whole expression is dynamic.

Strings, numbers, and booleans are inherently static. [DEPLOY variables](
#deploy-variables) are also static, because they are evaluated
before compilation.

The following examples are static expressions:

```coffeescript
  if "woem" == "meow" and DEPLOY.type == "debug" # static conditional
```

And the following are dynamic expressions:

```coffeescript
  if 10/2 == 5 or $cat == 'chantilly'
  if isCorrectAnswer($answer)
  local playerName = "Ellie"
  if playerName == DEPLOY.name # playerName is not a DEPLOY variable
```

## Customizing the Litexa DB Key

For variables that have database storage, Litexa maintains a single document in the
backing database, by default keyed to the Alexa request's deviceId field, meaning that
the data will be preserved for the skill running on the same Alexa device only.

Should you prefer to key on the userId instead (same skill data, no matter which device
in the same account runs it), or some other field, you can add the following function
anywhere in the skill's inline code.

```js
// The global `litexa` namespace contains compile-time objects at runtime.
// `overridableFunctions` can be redefined by assigning new functionality to them.
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
  // return a key based on both the deviceId and the request langauge
  return `${identity.deviceId}|${identity.litexaLanguage}`;
};
```