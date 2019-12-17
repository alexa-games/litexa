# Language Reference

## ->

Queues the next state to be executed after the current one
completes. The given name should refer to a state anywhere
else in the current project.

Note, this does *not* transition to the next
state immediately, the current state will always complete
first.

```coffeescript
  -> askUserForName
```

## @ variable

Defines a variable that will be stored permanently, and so
be accessible at any time, across all future requests to the skill.

You can directly read and write from an @ variable anywhere
in your code, the persistence mechanism will save it to your
database as appropriate.

```coffeescript
@username = "john"
if @username == "john"
  say "Hi, John"
```

@ variables are also supported directly in [Say String](#say-string) interpolation.

```coffeescript
say "Hello there, @username"
```

The name of the variable follows the rules for an [Identifier](#identifier).

## @ variable (Testing)

You can use [@ variable](#variable)s in Litexa test cases in 2 ways:

* compare their values using any of the [@ Variable
Comparison Operators](#variable-comparison-operators).
* assign a new value using the assignment operator `=`.

If your @ variable is an object or array, you can use
comparison operators on its members. However, object or
array compares are not compared by content values and will
fail (for the same reasons JavaScript will fail these):

```coffeescript
@testClass.val == 2 # will pass
@testClass == {val: 2} # will not pass
@someArray[0] == 'catfish' # will pass
@someArray == ['catfish','b','c'] # will not pass
```

For cases where you want to simulate the experience given a
particular stored state, you can use assignment to change
@ variable values.

If your @ variable is an object or array, you can
access its members/elements and modify those.

All the examples below are valid:

```coffeescript
@testClass = { val: 3}
@testClass.val = 3
@someArray[0] = "catfish"
```

For both of these operations, the right hand operand must be
a concrete value (cannot be a variable).

**Warning:** Don't place assignments and comparisons on the same variable in the
same location of the skill state. They do not necessarily execute in order.

## @ Variable Comparison Operators

A [@ variable (Testing)](#variable-testing) can use any of these operators:

| | |
| --- | --- |
| `==` | the values should be equal |
| `!=` | the values should *not* be equal |
| `<=` | the reference value should be less than or equal to the expression |
| `>=` | the reference value should be greater than or equal to the expression |
| `<` | the reference value should be less than the expression |
| `>` | the reference value should be greater than the expression |

## $ variable

Also known as a request variable, defines a variable that only
exists for the duration of the current request. Request variables remain in
scope anywhere after they are declared in the current request, and will be
released when a response is sent to the customer. Request variables are always
memory backed.

Request variables are dynamically scoped, and are always valid references.
Checking the value of an unassigned request scope variable will always yield a
falsy value, so they can be checked for existence with an [if](#if) or [unless](#unless)
statement.

$ variables are also supported directly in [Say String](#say-string) interpolation.

```coffeescript
say "Hello there, $username"
```

The name of the variable follows the rules for an [Identifier](#identifier).

There are three uses of $ variables:

* reserved variable [$request](#request)
* [slot variables](#slot-variables)
* [general use variables](#general-use-variables)

More information and examples of request variables can be found in the Variables and
Expressions chapter of the Book.

### $request

There is a reserved variable called `$request`. It is a read-only variable that
contains your raw skill request, whose schema is described in the [Request Types
documentation](https://developer.amazon.com/docs/custom-skills/request-types-reference.html).

Here is a sample IntentRequest type `$request` from running `litexa test` in a project:

```json
{
  ❝type❝:❝IntentRequest❝,
  ❝requestId❝:❝litexaRequestId.7633ae0e-ef82-41a1-b2a7-d0daf9659156❝,
  ❝timestamp❝:❝2017-10-01T22:02:10.000Z❝,
  ❝locale❝:❝default❝,
  ❝intent❝:{
    ❝name❝:❝MY_CAT_BREED❝,
    ❝slots❝:{
      ❝cat❝:{
        ❝name❝:❝cat❝,
        ❝value❝:❝nebelung❝
      }
    }
  }
}
```
### slot variables

The most common use of request variables is population of slot values in
intents. If an intent contains a slot value, Litexa will automatically populate
the $ variable defined in the handler from the skill request.

```coffeescript
askForCatName
  say "What is your cat's name?"

  when "my cat is named $name"
    or "$name"
    or "my cat's name is $name"
    with $name = AMAZON.US_FIRST_NAME
    say "$name you say. How cute!"
```

For the example above, Litexa will populate `$name` in the intent handler with
the value the skill received from the request. Therefore, if the user said "my
cat is named Ellie," then the skill would respond with "Ellie you say. How
cute!"

### general use variables

You can assign your own $ variables as a messaging system to affect
downstream states.

```coffeescript
launch
  say "hello!"
  $wasInLaunch = true
  -> askQuestion

askQuestion
  # this will be true if we came from the launch intent
  # but will be false if we did not.
  unless $wasInLaunch
    say "one more time, "
  say "what is your name?"

  when AMAZON.RepeatIntent
    -> askQuestion
```


## alexa:

Asserts that the skill winds up in an expected state at a
specific point in the interaction. It requires at least the
name of the expected state as an argument:

```coffeescript
  alexa: waitForName
```

If the skill session should end at that point, then write
`null` instead of a state:

```coffeescript
  alexa: null
```

This statement optionally takes in a whole say statement
to assert that the skill response matches the specified
text. You can specify a variable match or an exact match.

If your skill looks like this:
```coffeescript
launch
  say "Hello there."
    or "Hi there."
    or "<!Howdy>"
  -> askForName

askForName
  say "What's your name?"
    or "What is your name?"
  reprompt "Please tell me your name?"
  -> waitForName

waitForName
  when AMAZON.RepeatIntent
    say "Please tell me your name."
  ...
```

For a variable match, put the complete skill response text
(or any of its variations) in the statement. Then, the tests
below would pass:

```coffeescript
TEST "greeting"
  launch
  alexa: waitForName, "Hello there. What's your name?"

TEST "same greeting, different variation"
  launch
  # accepts either SSML shorthand or SSML
  alexa: waitForName, "<!Howdy.> What is your name?" # interchanges variations
  alexa: waitForName, "<say-as interpret-as='interjection'>Howdy.</say-as> What's your name?"
```

Note that you need to put complete statements. This means
the following would *not* pass:

```coffeescript
TEST "greeting - expect test to fail"
  launch
  alexa: waitForName, "Hello there."
  alexa: waitForName, "What's your name?"
```

You can also perform an exact match on the spoken text by
prepending the string with `e`. Thus, the following would pass:

```coffeescript
TEST "get to repeat"
  launch
  user: AMAZON.RepeatIntent
  alexa: waitForName, e"Please tell me your name."
```

Note that you cannot apply this when the say statements have
variations. The following would *not* pass:

```coffeescript
TEST "greeting - expect test to fail"
  launch
  alexa: waitForName, e"Hello there. What is your name?"
  alexa: waitForName, e"<!Howdy.> What's your name?"
  alexa: waitForName, e"Hi there."
```

Alternatively, you can provide a
[Regular Expression](#regular-expression) to match on a say
statement - this would allow you to perform partial or
pattern matches on say statements.

```coffeescript
launch
  say "<!Howdy.> What would you like me to do?"
  -> waitForResponse

waitForResponse
  when "roll a six sided die"
    say "Look at that, it came up with a {getD6Roll()}."
    END

TEST "roll die"
  launch
  alexa: waitForResponse, /<!howdy.> what would you like me to do\?/i # case insensitive regex to full speech
  user: "roll a six sided die"
  alexa: null, /it came up with a \w+/ # regex for partially matching speech
```


## buyInSkillProduct

Requires a case sensitive in-skill product reference name as an argument, where
the product must exist and be linked to the skill.

If the specified product exists, this sends a purchase directive *and* sets `shouldEndSession`
to true for the pending response (required for a Connections.Response handoff directive).

```coffeescript
buyInSkillProduct "MyProduct"
```

The above would send the following directive:

```json
{
  "type": "Connections.SendRequest",
  "name": "Buy",
  "payload": {
    "InSkillProduct": {
      "productId": "<MyProduct's productId>",
    }
  },
  "token": "<apiAccessToken>"
}
```

## cancelInSkillProduct

Requires a case sensitive in-skill product reference name as an argument, where
the product must exist and be linked to the skill.

If the specified product exists, this sends a cancellation directive *and* sets `shouldEndSession`
to true for the pending response (required for a Connections.Response handoff directive).

```coffeescript
cancelInSkillProduct "MyProduct"
```

The above would send the following directive:

```json
{
  "type": "Connections.SendRequest",
  "name": "Cancel",
  "payload": {
    "InSkillProduct": {
      "productId": "<MyProduct's productId>",
    }
  },
  "token": "<apiAccessToken>"
}
```

## capture

Takes a snapshot of the skill state at that point in time of
the test. Takes as an argument a name for the capture.

You can write multiple captures in a single test to snapshot
different points in time.

Please see [resume](#resume) for how to use the snapshot.

## card

Sends a card to the user's companion app with a title, an image, and/or text.

See the The Companion App chapter of the Book for more details.

```coffeescript
card "Welcome", image.png, "This is my wonderful card"
...
card "Another Way"
  image: image.png
  content: "Another way to initialize a card"
```

## Comments

Anything on a line after the # character is considered a comment, which means it will be ignored by the parser.
You can use comments to leave notes for yourself or for the next author to read
your code.

```coffeescript
# the score should only end up being between 1 and 10
switch score
  < 5 then
    say "You have room for improvement"
  < 9 then
    say "Almost there!"#comments can also happen after statements
  else
    say "Perfect!"

 TEST "run through" # in tests too
   launch#Comments All day long
   alexa: null
```

## define

Coming soon!

## directive

Adds directives to the next Alexa response, by calling an
[Inline Function](#inline-function). The function is expected to return
an array of JavaScript objects each representing a
single directive.

```coffeescript
directive createIntroAPLScreen()
```

For more on Alexa directives, see:
[Alexa Interfaces, Directives and Events](https://developer.amazon.com/docs/alexa-voice-service/interaction-model.html#interfaces)

## directive:

Much like [alexa:](#alexa) statements, asserts that a directive of
the specified type was sent in the skill response. This
matches any directive, regardless of whether it was sent
using a Litexa extension's added statements or not.

<details><summary>Example</summary>

```coffeescript
launch
  say "Welcome to the Cat Kingdom!"
  screen title.jpg # look at the Screens chapter for more on what this is
  END

TEST "launch"
  launch
  directive: Display.RenderTemplate
```

</details>

Note: You cannot assert the absence of any directive with this
command.

## END

Indicates that your skill should end after the next response, so
it should not expect any further interaction from the user.

## END (Testing)

Asserts that your skill response indicated that the skill
session should end.

For an example, see [LISTEN (Testing)](#listen-testing).

## Expression

Coming soon!

## for

Use a for loop when you need to iterate over an array or object.
For loops have the following syntax:

```
for <value> in <array | object>
```

or

```
for <key | index>, <value> in <array | object>
```

Given a scenario where we have these functions:

```javascript
getNames = function() {
    return {
      driver: 'bob',
      artillery: 'tim',
      hacker: 'mary'
    };
};
getNumbers = function() {
  return [3, 5, 8, 9];
}
```

You can iterate object values:

```coffeescript
for name in getNames()
  say "{name}"
```

This will output:

```
say bob
say tim
say mary
```

You can iterate object keys and values:

```coffeescript
for job, name in getNames()
  say "{job} {name}"
```

```
say driver bob
say artillery tim
say hacker mary
```

You can iterate array values:

```coffeescript
for number in getNumbers()
  say "{number}"
```

You can iterate array indices and values:

```coffeescript
for index, number in getNumbers()
  say "{index}{number}"
```

You can nest `for` loops:

**Warning:** You cannot reuse iterator names in the nested loop. In the below example
you could not use `i` for both loops.

```coffeescript
for i, j in getNumbers()
  for k, l in getNumbers()
    say "{i}{j}{k}{l}"
```

You can iterate and call asynchronous function in the `for` loop:

```coffeescript
for job, name in getNames()
  say "{processJobAsync(job)} {name}"
```


## Identifier

A word used to name things in code that must conform to the
following rules:

* It must begin with an ASCII letter or an underscore.
* It can then contain any combination of numbers, ASCII letters and underscores.
* It cannot be one of the [Reserved Word](#reserved-words)s.

```coffeescript
aName
aDifferentName
a_name
A_Thing_I_Named
counter1
counter_23
```

## if

The `if` statement lets you split between two behaviors,
based on the outcome of an [Expression](#expression). The block
following the `if` statement will only be executed if
the expression evaluates to true.

After the `if` statement, you can optionally add an `else`
statement, The block following that statement will only
be executed if the expression was false.

```coffeescript
if age >= 21
  say "Hey, would you like a beer?"
else
  say "Hey, would you like a soda?"
```

The unless statement is equivalent to the statement
`if not expression`, making it clearer that the code
block should only be executed if the test is negative.

```coffeescript
unless age < 21
  say "Hey, would you like a beer?"
```

## Inline Function

Coming soon!

## Intent Name

A code name used to refer to a specific type of intent, as part
of the [when](#when) statement.

An intent name consists of one or more [Identifier](#identifier)s, separated
by a `.`. You can create your own intent names to override the
default names created from your utterances, or you can refer
directly to the set of [Alexa built-in intents](https://developer.amazon.com/docs/custom-skills/standard-built-in-intents.html)

```coffeescript
waitForAnswer

  when TheAnswer
    or "The answer is $answer"
    say "Alright, checking your answer"

  when AMAZON.HelpIntent
    say "Just wait for my ring to light up blue, then tell me your answer."
    -> askQuestion

  when AMAZON.StopIntent
    say "Oh, alright then. See you later!"
    END
```

## jsonFiles

The object name that consolidates all `.json` files, keyed by the
 `.json` filename. To reference this within a Litexa file, you
 can use the object as you would any variable in a Litexa file.

 Here are some examples of referencing a `.json` file within
 a `.litexa` file.

 **Directory Structure**
 ```stdout
 project_dir
 └── litexa
     └── test.json
     └── main.litexa
 ```

 **test.json**
 ```json
 {
   "simple": "Reference me.",
   "test": "I am a test."
 }
 ```

 **main.litexa**
 ```coffeescript
 # File: main.litexa
 launch
   # Reference a JSON file as a variable
   local jsonTest = jsonFiles["test.json"]
   say "Simple. {jsonTest.simple}"

   # Reference a JSON file in-line
   say "Test. {jsonFiles["test.json"].test}"
 ```
 
## launch

Simulates the user invoking the skill in a Litexa test.
Starts the skill session in the `launch` state.

**Warning:** Litexa does not prevent you from using `launch` in the
middle of your test, such as after another intent. It will
take you to the `launch` state. However, on a real Alexa
device, this is equivalent to saying "Alexa, launch \<my
skill\>" in the middle of your skill session. Unless utterances for
launching skills are part of your skill model, your skill will most
likely receive some other intent instead.

## LISTEN

Indicates that your skill session should stay open after the next response.

It optionally takes in one of 2 arguments with the following effects:

* `microphone`: opens the device microphone, expecting the user to say something.
  This marks the response with `shouldEndSession: false`.
* `events`: does not open the device microphone, but does not end the skill session either.
  This marks the response with `shouldEndSession: undefined`. It is useful if
  you want to give your users more time to think and require them to prefix their
  response with the wake word, or are expecting other types of input,
  such as a `GameEngine.InputHandlerEvent`.

If no argument is given, it defaults to `LISTEN events`.

By default, `LISTEN microphone` is the behavior for the end of a state handler,
so you are not required to write it in your state handlers to expect users
to respond to your skill.

Keep in mind, this does not gate the kind of skill request that your skill
may receive in that state; all intents and events supported by your skill
may still come in regardless of this setting.

## LISTEN (Testing)

Asserts that your skill response indicated that the skill
session should stay open. It optionally takes in one of 2
arguments with the following effects:

* `microphone`: asserts that the response would open the
device microphone. This checks that the response has
`shouldEndSession: false`.
* `events`: asserts that the response would *not* open the
device microphone. This checks that the response has
`shouldEndSession: undefined`.

If no argument is given, it defaults to `LISTEN events`.

<details><summary>Example</summary>

If your skill looks something like this:

```coffeescript
launch
  say "Are you a cat person or a dog person?"
  -> waitForAnswer

waitForAnswer
  # no LISTEN statement here implies LISTEN microphone
  when "cat"
    say "Meow"
    END
  when "dog"
    say "Bork"
    END
```

Then you can assert your skill state and microphone like so:

```coffeescript
TEST "user says cat"
  launch
  LISTEN microphone # replacing this with LISTEN or LISTEN events will cause the test to fail
                    # because it is expecting the microphone to open
  user: "cat"
  END
```

</details>


## local

Defines a variable much like traditional variables in that
they are lexically scoped, meaning that their lifespan will align
with the block of code they sit in, and they will be visible to any code inside that block.

Local variables must be declared before use, with the `local` statement,
and cannot be declared again in the same scope, including in subordinate blocks of code:
*Litexa does not allow variable shadowing.*

Local variables must also be initialized with a value.

```coffeescript
launch
  local counter = 0
  local name = "Jane"
  local flag = false
```

Local variables that are declared and used in a single handler have memory storage.
Local variables can survive across more than one handler though, when declared
in the state's entry handler and then referenced in any of the state's intent
handlers or the state's exit handler. In this case, they are automatically promoted
to database storage.

**Warning:** Reentering a state will reset its "persistent" local variables, since it
will call the initialization in the state's entry handler.

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

## log

Writes the result of the given [Expression](#expression) to your logging system.

In the standard `@litexa/deploy-aws` library, this will write
to your Lambda's Cloudwatch log.

## logStateTraces

Prints out every subsequent state transition and intent handler
encountered until the end of of the current test. Use this
if you suspect your state transition logic isn't doing exactly
what you think it should be.

You will need to add `= true` or `= false` as an argument to
enable and disable it, respectively. You can have multiple
statements throughout your test, with at most one for each
skill request-producing interaction.

<details><summary>Example</summary>

```coffeescript
TEST "find the cat"
  launch
  user: "left"
  logStateTraces = true # output states traversed
  user: "right"
  user: AMAZON.YesIntent
  user: AMAZON.RepeatIntent
  logStateTraces = false # stop showing states traversed
  user: "pick up the cat"
  user: AMAZON.NoIntent
```

</details>

## metric

Records a single counter metric to the metric database. You
can use this to keep track of how many times a given thing
has happened in your skill.

The metric name can be any combination of numbers, letters
and the `-` symbol.

```coffeescript
metric playerCompletedGame
```

The standard @litexa/deploy-aws package will write
these to cloudwatch. If you are using a different package,
please see its documentation for how metrics are routed.

## or

Used to provide variations to various statements:
* [say](#say)
* [when](#when)
* [soundEffect](#soundeffect)

## otherwise

Defines a catch all intent that will be executed should
its parent state receive an intent that it has no explicit
handler for. It's always possible for the user to say
something unexpected, so you should generally always have
something to say to guide them back on track in these cases.

```coffeescript
waitForAnswer

  when TheAnswerIs
    say "alright, checking"

  otherwise
    say "I'm sorry, I didn't quite get that. Let's try again."
    -> askQuestion
```


## playMusic

Issues an [AudioPlayer Play](https://developer.amazon.com/docs/custom-skills/audioplayer-interface-reference.html#play)
directive, and automacially adds the required `AUDIO_PLAYER` interface to the skill manifest.
Playback can be stopped with the [stopMusic](#stopmusic) statement.

The statement requires a sound target parameter, which can be a deployed asset's name or an
existing URL. The directive will stream the target audio, and bring up a visual audio player
interface on screen devices. The supported target audio formats include AAC/MP4, MP3, and HLS, and
the source audio's bit rate must fall between 16 kbps and 384 kbps.

```coffeescript
# assuming a compatible sound.mp3 is deployed via litexa/assets:
playMusic sound.mp3

# or, assuming the URL points to a compatible sound file:
playMusic "https://www.example.com/sound.mp3"
```

## pronounce

Specifies a one for one replacement that will be automatically
applied to all voiced responses from this skill. The statement
should be placed outside of the scope of any state, at the top
level of the file.

Use this to improve Alexa's pronunciation of words, or select
a specific pronunciation skill wide, while retaining human
readable spelling in your code.

```coffeescript
pronounce "tomato" as "<phoneme alphabet="ipa" ph="/təˈmɑːtoʊ/">tomato</phoneme>"
```

Note that you must use SSML in the replacement text; the Litexa
SSML shorthand statements (e.g "<!Bravo>") will not work.

### localized pronunciations

If you plan to publish your skill to multiple locales, you can define
locale-specific pronunciations for your voiced responses. Simply add
your locale-specific pronunciation definitions to the Litexa files that
reside in said locale's Litexa project directory.

::: tip Use a pronounce.litexa file in each locale's Litexa project directory
If defining locale-specific pronunciations, we recommend creating a
pronounce.litexa file in each of your locale's Litexa project directories.
Put all of your locale-specific pronunciation definitions inside of it.
:::

::: warning The default locale's pronunciations do not carry over to other locales
Because pronunciations are very locale-specific, the default locale's pronunciations
will not carry over to other locales.
:::

## quit

Coming soon!

## Regular Expression

Litexa supports a subset of [JavaScript's regular
expressions](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions).

In brief, a regular expression, or regex for short,
is a compact program designed to recognize strings.
They begin and end with the `/` character.

The simplest regex matches an exact string:

```coffeescript
/bob/
```

This matches the exact string 'bob'. We can make the
match case insensitive by adding an `i` flag.

```coffeescript
/bob/i
```

This matches 'Bob', 'bob', and all combinations in
between.

We can use the `|` character to provide alternates.

```coffeescript
/red|green|blue/
```

The `.` character stands in for any single character.

```coffeescript
/o.o/
```

This would match 'ooo', 'owo', 'ovo', and so on.

The `?` character specifies that the string should have
zero or one occurrences of the preceding character.

```coffeescript
/flavou?r/
```

This would match both 'flavor' and 'flavour'.

The `+` character specifies that the string should have
one or more occurrences of the preceding character.

```coffeescript
/ca+t/
```

This would match 'cat', 'caat', 'caaat', etc.


## reprompt

Specifies the reprompt that will be installed during
the next response. The content is specified in the
[Say String](#say-string) format.

Note: Unlike [say](#say) statements, reprompt statements
are *not* accumulative; only the most recent reprompt statement
will be included in the response.

## request:

Coming soon!

## Reserved Word

A reserved word is any word reserved for the language's
use and thus unavailable for any user defined names.

The full list:
* [capture](#capture)
* [card](#card)
* [define](#define)
* [directive](#directive)
* [END](#end)
* [for](#for)
* [in](#for)
* [if](#if)
* [else](#else)
* global
* [launch](#launch)
* [LISTEN](#listen)
* [microphone](#listen)
* [events](#listen)
* [local](#local)
* [log](#log)
* [logStateTraces](#logstatetraces)
* [metric](#metric)
* [or](#or)
* [otherwise](#otherwise)
* [pronounce](#pronounce)
* [quit](#quit)
* [reprompt](#reprompt)
* [resume](#resume)
* [say](#say)
* [set](#set)
* [setRegion](#setregion)
* [setResponseSpacing](#setresponsespacing)
* [switch](#switch)
* [TEST](#test)
* [then](#then)
* [unless](#unless)
* [wait](#wait)
* [when](#when)
* [with](#with)

## resume

Continues a skill from the state saved by [capture](#capture). Takes
as an argument a name for the snapshot to resume.

The order that `resume`s and their dependent `capture`s are
listed in the file does not matter - Litexa will sort out
the dependency tree for you and run your tests in that
order.

<details><summary>Example</summary>
If your skill looks something like this:

```coffeescript
launch
  say "Please say 'apple.'"
  -> waitForApple

waitForApple
  when "apple"
    say "Now, say 'banana.'"
    -> waitForBanana
  otherwise
    say "You didn't say apple. Try again."

waitForBanana
  when "banana"
    say "You did it. Goodbye."
    END
  otherwise
    say "You didn't say banana. Try again."
```

Then you could succinctly cover all handlers with the
following tests:

```coffeescript
TEST "apple -> apple"
  launch
  user: "apple"
  alexa: waitForBanana
  capture userSaidApple # unquoted name of the capture
  user: "apple"
  alexa: waitForBanana

TEST "apple -> banana"
  resume userSaidApple # resume from the named capture
  user: "banana"
  alexa: null

TEST "banana -> apple"
  launch
  user: "banana"
  alexa: waitForApple
  user: "apple"
```
</details>

You can also write multiple captures in a single test to
snapshot different points in time. However, it is
recommended to only resume once per test. Resuming will
override your test's current state with the snapshotted
state. Keep in mind that `resume` resumes *skill state*, not
the sequence of statements in the written test.


## say

Adds spoken content to the next response. The content
is specified in the [Say String](#say-string) format.

Say statements are accumulative until the next
response is sent, with each subsequent statement
being separated by a single space.

```coffeescript
say "Hello"
say "World"
```

This would result in Alexa saying "Hello World"

## Say String

The Say String format is used by [say](#say) and [reprompt](#reprompt) statements,
and supports any of the following:

1. Alphanumerical characters and punctuation:

```coffeescript
say "Basic statement with letters, the numbers 1, 2, 3, and punctuation."
```

2. Interpolated [@](#variable) DB variables and [$](#variable-2) slot variables:

```coffeescript
@myDbVar = 'myDbVar'
say "My DB variable's value is @myDbVar."

when "my name is $name"
  with $name = AMAZON.US_FIRST_NAME
  say "Your name is $name."
```

3. Interpolated [expressions](#expression):

```js
function echo(str) { return str; }

const myConst = 'my constant'
```

```coffeescript
say "{1 + 1}"               # says "2"
say "{echo('test')}"        # says "test"
say "constant is {myConst}" # says "constant is my constant"

@intro = 'Hello '
when "my name is $name"
  with $name = "Bob"
  say "{@intro + $name}!"  # says "Hello Bob!"
```

4. Explicit [SSML](https://developer.amazon.com/docs/custom-skills/speech-synthesis-markup-language-ssml-reference.html):

```coffeescript
# Note the required escape slashes before the opening/closing SSML tags!
say "\<say-as interpret-as='ordinal'>1\</say-as>"
# says "first"
```

5. Shorthand [SSML](https://developer.amazon.com/docs/custom-skills/speech-synthesis-markup-language-ssml-reference.html),
which facilitates using the following tags:
* [Interjections](https://developer.amazon.com/docs/custom-skills/speechcon-reference-interjections-english-us.html)

```coffeescript
say "<!abracadabra>"
# shorthand for: "<say-as interpret-as="interjection">abracadabra!</say-as>"
```

* [Break time](https://developer.amazon.com/docs/custom-skills/speech-synthesis-markup-language-ssml-reference.html#break)

```coffeescript
say "Before pause. <...100ms> After 100 millisecond pause."
# shorthand for: "Before pause. <break time='100ms'> After 100 millisecond pause."
```

* [Audio](https://developer.amazon.com/docs/custom-skills/speech-synthesis-markup-language-ssml-reference.html#audio)

```coffeescript
# assuming a sound.mp3 file is deployed with skill, via litexa/assets
say "playing sound effect <sfx sound.mp3>"
# shorthand for: "playing sound effect <audio src='[deployed_mp3_url]' />"
```

6. Multi-line strings:

```coffeescript
say "Multiline
  string!
  <!abracadabra>!"

# says: "Multiline string!<say-as interpret-as='interjection'>abracadabra</say-as>!
```

7. Combinations of multiple components:

```coffeescript
say "<!aloha>. This {'is ' + 'an ' + 'example'}
  of <...100ms> multiple
  \<amazon:effect name='whispered'>components\</amazon:effect>."
```

## set

Allows for setting skill context flags to true or false.

* `resetOnLaunch`
  * true (default): every skill launch request will start the skill in the
  `launch` state
  * false: if the last skill session wasn't intentionally ended, this
  will attempt to restore the last skill sesssion's pre-termination state

  ```coffeescript
  launch
    set resetOnLaunch false
  ```

## setRegion

Run the test in the specified region until the end of the
Litexa test case.

It takes in one of 2 arguments:

* language code: format [a-zA-Z][a-zA-Z]
* locale code: format [a-zA-Z][a-zA-Z]-[a-zA-Z][a-zA-Z]

The default region is en-US.

If you would instead like to run all your tests in a
specified region, you can use the `-r` flag in `litexa test`
which takes the same arguments as above. Litexa will tell
you in the test output which litexa file region will be
used, such as below:

```
Testing in region en-US, language default out of ["default"]
```

For context on the usage of this statement, read the Localization chapter of the
Book.


## setResponseSpacing

Sets a timeout (in milliseconds) before the next response is sent. This can be
used to prevent a user request from triggering a new response before the
ongoing response has finished.

This isn't relevant for a vocal intent, since giving a vocal intent requires
either the microphone being open (meaning the response has finished), or
the wake word being used (which actively interrupts the response).

However, it is relevant for something like Echo Buttons, as users pressing their
buttons sometimes shouldn't interrupt the ongoing response. An example for this
would be a roll call:

```coffeescript
rollCall
  when GameEngine.InputHandlerEvent "NewButton"
    say "This is a welcome message that takes approximately 3000 milliseconds."

  # While in roll call, add a delay of 3 seconds between welcome messages. That way,
  # new players joining back to back won't interrupt the previous welcome message.
  setResponseSpacing = 3000
```

## soundEffect

Converts a specified sound effect to SSML, and adds it to the next response.
Importantly, only sound effects in an
[Alexa-friendly format](https://developer.amazon.com/docs/custom-skills/speech-synthesis-markup-language-ssml-reference.html#h3_converting_mp3)
are playable. The sound effect can be specified as a:

1. URL:

```coffeescript
soundEffect "https://www.example.com/sound.mp3"
```

2. file name (assuming the file is placed in `litexa/assets` and deployed):

```coffeescript
# assuming sound.mp3 is placed in litexa/assets and deployed with the skill
soundEffect sound.mp3
```

3. [ASK sound library](https://developer.amazon.com/docs/custom-skills/ask-soundlibrary.html) reference:

```coffeescript
soundEffect "soundbank://soundlibrary/animals/amzn_sfx_bear_groan_roar_01"
```

All three of the above specifications can alternatively be used in the `<sfx>`
tag in [Say Strings](#say-string).

## State

A state is defined by writing an [Identifier](#identifier) as the
first and only thing on its own line.

See the State Management chapter of the Book, for more information.

## stopMusic

Issues an [AudioPlayer Stop](https://developer.amazon.com/docs/custom-skills/audioplayer-interface-reference.html#stop)
directive. The directive halts any ongoing AudioPlayer stream (e.g. such as one started with the
[playMusic](#playmusic) statement).

```coffeescript
stopMusic
```

## switch

A switch statement lets you split the flow between
any number of mutually exclusive possibilities, each
defined by a case statement ending with
the keyword `then`.

The switch statement can optionally include a reference
value that each case can compare against, specified as
an argument after the `switch` keyword.

```coffeescript
switch age
  < 1 then
    say "it's a baby"
  < 3 then
    say "it's a toddler"
  < 12 then
    say "it's a child"
  < 18 then
    say "it's a teenager"
  else
    say "it's a grown up"
```

Each `switch` will only execute one of its cases,
the first one that is eligible. If another case further
down the list is also eligible, it will be skipped.

The `else` case is executed if none of the other cases
are eligible.


There are three kinds of case statements:

* [Switch Comparison Case](#switch-comparison-case)
* [Switch Expression Case](#switch-expression-case)
* [Switch Regular Expression Case](#switch-regular-expression-case)


## Switch Comparison Case

A [switch](#switch) case statement can begin with one of the
[Switch Comparison Operators](#switch-comparison-operators). This will compare the
[switch](#switch)'s reference value directly against the
case's [Expression](#expression) value.

```coffeescript
switch card
  == @luckyCard then
    say "That's it, you found the lucky one!"
  == 'a' then
    say "You have an ace"
  == 'j' then
    say "You have a jack"
  < 5 then
    say "You have a low number card"
  <= 10
    say "You have a high number card"
  else
    say "I have no clue what card you have..."
```

## Switch Comparison Operators

A [Switch Comparison Case](#switch-comparison-case) can
begin with any of these operators:

| | |
| --- | --- |
| `==` | the values should be equal |
| `!=` | the values should *not* be equal |
| `<=` | the reference value should be less than or equal to the expression |
| `>=` | the reference value should be greater than or equal to the expression |
| `<` | the reference value should be less than the expression |
| `>` | the reference value should be greater than the expression |

## Switch Expression Case

A [switch](#switch) case can have a full expression, and will be
eligible as long as the expression resolve to a truthy value.

```coffeescript
local someNumber = getNumber()
switch
  someNumber * 2 == 10 then
    say "Your number is 5!"
  someNumber / 2 == 5 then
    say "Your number is 10!"
  else
    say "Your number is neither 5 nor 10."
```


## Switch Regular Expression Case

When you need to fuzzy match a string, you can use a
[Regular Expression](#regular-expression) as the case statement to directly
test the [switch](#switch)'s reference value.

```coffeescript
switch characterName
  match /Jack|Bob/ then
    say "Hey guys, what's up?"
  match /Rose/i then
    say "Long time no see, Rose"
  match /.*elle/ then
    say "Bonjour, {characterName}"
```

## TEST

Names a Litexa test case. All statements in the test will
then be indented.

```coffeescript
TEST "first time user interaction"
  launch
  ... # rest of the test case
```

## then

Terminates case statements for the [switch](#switch) statement.

## unless

The negated version of the [if](#if) statement. Note: unless
statements do not support a dependent else statement.

## upsellInSkillProduct

Requires a case sensitive in-skill product reference name as an argument, where
the product must exist and be linked to the skill. Supports an upsell `message` string, to be
communicated to the user prior to prompting a purchase (should be a Yes/No question).

If the specified product exists, this sends an upsell directive *and* sets `shouldEndSession` to
true for the pending response (required for a Connections.Response handoff directive).

```coffeescript
upsellInSkillProduct "MyProduct"
  message: "My product's upsell message. Would you like to learn more?"
```

The above would send the following directive:

```json
{
  "type": "Connections.SendRequest",
  "name": "Upsell",
  "payload": {
    "InSkillProduct": {
      "productId": "<MyProduct's productId>",
    },
    "upsellMessage": "My product's upsell message. Would you like to learn more?"
  },
  "token": "<apiAccessToken>"
}
```

## user:

Sends skill intent requests to the skill to drive test
execution. Intents are specified by either one of its
utterances or name:

```coffeescript
user: "start the game over please" # by utterance
user: NameIntent # by name
```

If a slot value is needed, it can be specified in an
utterance directly, or it can be appended to the end of the
statement.

For example, if a handler in the skill looks like this:

```coffeescript
  when NameIntent
    or "my name is $name"
    or "$name"
    with $name = AMAZON.US_FIRST_NAME
```

Then the following statements behave the same way in your test:

```coffeescript
user: "my name is Cat" # Litexa deduces $name = Cat from the utterance
user: NameIntent with $name = Cat # append more slots by separating them with commas
user: "my name is" with $name = Cat # this is valid, but can't happen in a real interaction
```


## wait

Simulates a designated amount of time to pass in a Litexa test case.
The Litexa test framework automatically increments time
passing for every interaction, so this would be useful if
you need a minimum amount of time to pass to trigger some
condition in the skill.

This statement takes 2 arguments:

* an integer (positive or negative)
* one of {`second(s)`, `minute(s)`, `hour(s)`, `day(s)`}

<details><summary>Example</summary>

```coffeescript
launch
  if minutesBetween(context.now, @lastLaunchTime) > 15
    say "Welcome back! We spoke more than 15 minutes ago."
  else
    say "Greetings, young grasshopper."
  @lastLaunchTime = context.now
  END

TEST "test welcome back speech"
  launch
  alexa: null, "Greetings, young grasshopper."
  launch
  alexa: null, "Greetings, young grasshopper."
  wait 2 hours
  launch
  alexa: null, "Welcome back! We spoke more than 15 minutes ago."
```

</details>

**Negative wait time:** Litexa will honor negative time values in your tests.
This may be useful if you think Litexa is making too much time pass between
interactions and you would like to test something time-sensitive that won't
simulate properly otherwise.


## when

Defines an intent that the parent state is willing to handle.

```coffeescript
when "my name is $name"
```

The intent will be rolled into the Alexa skill model for
your skill. The code subordinate to this statement will
be executed when your skill receives the intent *and* is in
this state.

This statement is part of a larger *when clause*, beginning with
a `when`, followed by optional subordinate `or` and [with](#with)
statements.

The content of the statement can be an [Utterance](#utterance), or an
[Intent Name](#intent-name). In either case, the statement can be followed
by a series of subordinate [or](#or) utterance statements that offer
alternative ways to specify the same intent.

```coffeescript
when "my name is $name"
  or "I'm $name"
  or "call me $name"
```

When the `when` statement contains an [Utterance](#utterance), the underlying
intent name will be automatically generated from that utterance,
e.g. `MY_NAME_IS_NAME` for the above example.

You can reuse the same intent in different states by specifying
the identical `when` statement; you only have to define the set
of alternate utterances once.

```coffeescript
askForName
  say "what is your name?"

  when "my name is $name"
    or "the name is $name"
    or "call me $name"
    say "Got it, thanks!"

askForAlternateName
  say "what should I call you on the weekend?"

  when "my name is $name"
    say "Understood."
```

When the statement contains an [Intent Name](#intent-name) instead, if the
name is unique to this skill, then at least one `when` statement
specifying it must be followed by an or statement in order to
define at least one utterance for the intent. As per above,
other locations need not repeat the utterances.

```coffeescript
askForName
  say "what is your name?"

  when MyNameIs
    or "my name is $name"
    or "call me $name"
    say "Got it, thanks!"

askForAlternativeName
  say "what should I call you on the weekend?"

  when MyNameIs
    say "Understood."
```

## with

Specifies the type of a [slot](#slot), as part of a [when](#when) clause.

The contents of the statement refer to the name of the slot
in question, and the type it should be expected to receive.

The type may be specified as either a built in [Alexa slot type](https://developer.amazon.com/docs/custom-skills/slot-type-reference.html)
or as a list of possible values, or as an [Inline Function](#inline-function)
call, where you can build your own slot values.

To use a built in slot type, just specify it directly as the
type in the statement, in this case "AMAZON.US_FIRST_NAME"

```coffeescript
when "My name is $name"
  with $name = AMAZON.US_FIRST_NAME
```

To use a list of possible values, provide a comma separated
list of strings instead

```coffeescript
when "My favorite pet is $pet"
  with $pet = "dog", "cat", "bird"
```

Finally, the most comprehensive option is to use an inline
code function to supply the values. To do this, use the
source filename, followed by a colon, followed by the
function name you'd like to use:

```coffeescript
when "I'll be traveling by $vehicle"
  with $vehicle = slots.build.js:vehicleNames
```

Your source file will be expected to write one or more slot
building functions to the `exports` object.

Each slot building function will expected to return a single
object like the type definition portion of the [Alexa
language
model](https://developer.amazon.com/docs/custom-skills/create-and-edit-custom-slot-types.html#json-for-slot-types-interaction-model-schema).

```javascript
    // in slots.build.js
exports.vehicleNames = function() {
  return {
    name: "LIST_OF_VEHICLES",
    values: [
      {
        "id": "TRAIN",
        "name": {
          "value": "train",
          "synonyms": [
            "taking the train",
            "train ride",
            "choo choo"
          ]
        }
      },
      {
        "id": "FLY",
        "name": {
          "value": "plane",
          "synonyms": [
            "flying",
            "jet",
            "fly",
            "on an airplane"
          ]
        }
      },
      {
        "id": "DRIVE",
        "name": {
          "value": "car",
          "synonyms": [
            "driving",
            "auto",
            "automobile",
            "taking a road trip",
            "road trip"
          ]
        }
      }
    ]
  }
}
```

If your intention is to use a simpler list of words, then you can
use a shortcut and return an array of strings for the values key:

```javascript
// in slotbuilder.js
exports.vehicleNames = function() {
  return {
    name: "LIST_OF_TRAVEL_MODES",
    values: [ "train",
      "train",
      "jet",
      "fly",
      "plane",
      "on an airplane",
      "car",
      "auto",
      "automobile",
      "taking a road trip",
      "road trip"
    ]
  }
}
```
