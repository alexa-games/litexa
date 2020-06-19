# Testing

Litexa comes with extra syntax and tooling to test the logic
in your Litexa and inline code files. Litexa testing is done
offline, helping you catch a variety of common problems
before you deploy your skill to Alexa. Litexa testing can
also be run in a "watch" mode, automatically running all
your tests in the background whenever you save any of your
code files.

In this chapter you will learn how to write
Litexa tests, and gain familiarity with Litexa testing tools.

What does Litexa test? Simply put, you can simulate your
skill! Litexa tests locally simulate the interaction between
a user and your skill. They allow you to check the branches
of your skill flow and your skill's saved state at each
interaction step.

## Why should I test my skill?

Writing tests for your skill will allow you to catch bugs
and be aware of where functionality changes as you iterate
on your skill.

## Where do I put my tests?

### Litexa tests

Tests are to be written in `*.test.litexa` files. A
recommendation is to name them after your `*.litexa` files,
and to write tests pertaining to that file in them.

Running these tests results in a transcript of the
interaction. A test run also produces detailed artifacts for
inspection in a `.test` report subdirectory under your
project. As with the `.deploy` directory, you are free to
delete this directory without impacting your project, and
should ignore it in your source control program.

:::tip Alternate Litexa test locations
Tests can also be written in your `.litexa` files
alongside your Litexa code. If you find that useful, this
allows you to write a test next to the state you're testing.
In general though, it is better to organize your code and
tests into their own files.
:::

More information about the `.test` directory can be found at
the bottom of this chapter in [.test Directory Contents](#test-directory-contents).

### Code tests

As you would any other coding project, you can write tests
to test the functionality of your code. Please refer
to the [Project Structure
Chapter](/book/project-structure.html) to know where
your test files should go.

## Where do I start?

Let's get started by reading a test file and its execution
output, so that you can understand what Litexa presents to
you.

Litexa's generated project comes with accompanying tests.
Let's walk through them. The `main.test.litexa` file looks
like this:

<<< @/packages/litexa/src/command-line/templates/common/litexa/main.test.litexa

To run tests, type `litexa test` into your command line. You
will get the following result:

<<< @/docs/book/generatedProjectTestOutput.txt

You can observe in the output structure that 3 tests were
performed, of which 2 look like simulation transcripts. If
you look at the test file, you can see from the indentation
that there are 2 tests: "happy path" and "asking for
help." At the top of the test output, you can see that the
name of the first two test steps match. These
two are Litexa tests.

Now, let's take a closer look. Like your standard unit test,
Litexa tests contain a mix of command steps (analogous to
function calls) and verification steps.

### Command Steps

Litexa's test command steps represent real skill input,
or skill requests. They are simplified to user-spoken
dialogue, intents, or other skill request types. In other words,
Litexa test execution simulates user input.

In the "happy path" test case, the
command steps are `launch` and `user: "..."`. These are
equivalent to skill requests and drive
the skill execution. The skill steps through its Litexa
states from the handler relevant to that
skill request, and at the end of each state flow, produces a
skill response and saves the state data.

Litexa test output per command step has the following
structure:

```
[Step Number] [Request Info] [$slotName=slotValue] @ [simulation timestamp]
◖----------------◗ [Spoken Response] ... [Reprompt]
[user log output]
[test-state changes or other relevant events]
```

So in "happy path," the `launch` statement triggers a
LaunchRequest, which produces the following test output:

```shell
2.  ❢    LaunchRequest    @ 15:01:05
     ◖----------------◗ "Hi there, human. What's your name?" ... "Please tell me your name?"
```

Then, the following `user: "my name is Dude"` maps to the
MY_NAME_IS_NAME intent. Litexa automatically matches the
user dialogue with one of the intent's defined utterances
and fills in the slot value that matches its utterance
structure. You can see the result of that test statement below:

```shell
4.  ❢   MY_NAME_IS_NAME  $name=Dude @ 15:02:10
     ◖----------------◗ "Nice to meet you, Dude. It's a fine Monday, isn't it? Bye now!" ... NO REPROMPT
  ◣  Voice session ended
```

Here, you can see what intent was understood, and how the slot
was populated. The skill picks up where it left off, which
in the code is the `waitForName` state. You can see the result
of the say statement, and that no reprompt was given.
You can also see that the session ended with this response.

The next launch session reopens the skill. The skill
retained its state from the last response, so we can see
that the skill response uses the logic branch that says the
stored name "Dude".

```shell
8.  ❢    LaunchRequest    @ 15:03:15
     ◖----------------◗ "Hello again, Dude. Wait a minute... you could be someone else. What's your name?" ... "Please tell me your name?"
```

### Verification Steps

Now that we've covered command steps, let's look at the
other statements in your test cases. The rest of these
statements are verification statements that assert
conditions you expect to be true at that point in the
simulation.

The first statement, `alexa: waitForName`
expects the skill to end up in the `waitForName` state
when it sends its skill response.

The second, `@name == "Dude"`, compares the value of the
database variable `@name` in the skill. Litexa tests have
context about the skill state, so it is possible to verify
its data components.

The third and last unique test statement, `END` asserts the
skill closed the skill session.

Some verification steps execute silently to not pollute the
output if the condition passes. (Note: All of the test
statements in this example don't produce verification
output.) If the test fails, it will display the failure
reason in the test output.

For example, if we change the test's verification steps as
follows:

```coffeescript
TEST "happy path"
  launch
  alexa: askForName # should fail here
  user: "my name is Dude"
  @name == "Imposter" # should fail here, too
  END
  ... # rest of the test statements
```

Then the resulting test output would be:

```coffeescript
✘ 3 tests run, 1 failed (104ms)

Testing in region en-US, language default out of ["default"]
✘ test: happy path
3.  ❢    LaunchRequest    @ 15:01:05
   ✘ ◖----------------◗ "Hi there, human. What's your name?" ... "Please tell me your name?"
     ✘ response was in state `waitForName` instead of expected `askForName`
5.  ❢   MY_NAME_IS_NAME  $name=Dude @ 15:02:10
   ✘ ◖----------------◗ "Nice to meet you, Dude. It's a fine Monday, isn't it? Bye now!" ... NO REPROMPT
  ◣  Voice session ended
     ✘ db value `name` was `"Dude"`, not equal to `"Imposter"`
9.  ❢    LaunchRequest    @ 15:03:15
     ◖----------------◗ "Hello again, Dude. Wait a minute... you could be someone else. What's your name?" ... "Please tell me your name?"
11.  ❢   MY_NAME_IS_NAME  $name=Rose @ 15:04:20
     ◖----------------◗ "Nice to meet you, Rose. It's a fine Monday, isn't it? Bye now!" ... NO REPROMPT
  ◣  Voice session ended
```

You can see that the test failed in the spots marked by the
`✘`. The indented description below the skill response gives
more details about why the test failed. From there, you can
check either your skill logic or test case to see which one
to fix.

:::tip Tracking states in test output
If you'd like to step through which states your skill went
through for its skill responses, you can enable the state
tracing option in your tests. This will print out the states
traversed in the test output. Go to the [logStateTraces
reference](/reference/#logstatetraces) for instructions on
usage.
:::

For the full syntax for writing Litexa tests, go to the
[Litexa Test Statements](#litexa-test-statements) section below.

### Code tests

Finally, there's one last test we've been ignoring until
now, which is the code test. This type of test verifies your
inlined CoffeeScript/JavaScript/TypeScript code's individual
functionality. Usually, these
are utility functions you plug into your Litexa code. Take a
look at the [JavaScript Interoperation
Chapter](/book/interop.html) for a better understanding of
inlined code.

The generated project has one code test case, located in
`utils.test.coffee/js/ts` or `utils.spec.coffee/js/ts`,
which tests the functionality in `utils.coffee/js/ts`. For
these kinds of tests, you would use the [Test
class](/reference/inlined-code-tests.html).


Here is the test case:

```javascript
Test.expect("stuff to work", function() {
  Test.equal(typeof (todayName()), 'string');
  Test.check(function() {
    return addNumbers(1, 2, 3) === 6;
  });
  return Test.report(`today is ${todayName()}`);
});
```


Here is the piece of code it tests:

```javascript
function todayName() {
  let day;
  day = (new Date).getDay();
  return ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][day];
}

function addNumbers(...numbers) {
  let i, len, num, result;
  console.log(`the arguments are ${numbers}`);
  result = 0;
  for (i = 0, len = numbers.length; i < len; i++) {
    num = numbers[i];
    result += num;
  }
  return result;
}
```


And here is its test output again:

```shell
✔ utils.test.js, 1 tests passed
  ✔ utils.test.js 'stuff to work'
  c! the arguments are 1,2,3
  t! today is Monday
```

You can see that the test case shows the name of the test in
the output. The `c!` line corresponds to the `console.log`
statement in the function, and the `t!` line corresponds to
the `Test.report` statement in the test case. Like Litexa
tests, the other Test class statements are silent.

:::tip Console statements
Any `console.*` statements in your code files will show up
in your test output. This may be useful for debugging as you
iterate on your skill code.
:::

Note that you can only write tests for inlined Litexa code,
which is code accessible to your Litexa code files. This
means if you are testing functionality in a different
module (because of your bundling strategy), you can't test
this function in this project location. Instead, you can
and should test it within that module's test location.

As a reflection of your code complexity, if your code starts
to get too complex, it is recommended to move it out to
separate modules. See the [Project
Structure](/book/project-structure.html) chapter on
which project structure is right for you.

## Litexa Test Command Line

You can run `litexa test` from anywhere in your Litexa
project. The command is sufficient for all your Litexa tests
and inlined code tests, but there are a few options you can tack
onto the command for extended capabilities.

### Command Line Options

Running `litexa test --help` will output the flags you can
attach to the command. Below is an elaboration on their
effects:

* `--no-strict`: turn some would-be errors from building the skill
  into console errors instead.
* `--device [device]`: which device to emulate; the only functional difference
  is that `show` will contain screen directives (see
  [Screens Chapter](/book/screens.html) if they are
  part the skill response and the other devices will not
  have them.
  * options are `echo`, `dot`, and `show`, with `show` as
    default
* `--log-raw-data [logRawData]`: dumps all requests, responses, and
  DB contents into .test/output.json
* `--watch/-w`: rerun tests after any file changes in your
  Litexa project. This is handy for the rapid iteration
  stage of development and testing because you can trap
  problems as soon as they happen.

You can also specify `--region/-r [region]` to run your
tests in the specified locale.

### Test Filtering

There is one more feature, and that is filtering. You can
filter which tests to run in that command by specifying part
of the name of the test(s) you want to run or the name of the
file. You can combine
this with `-w` in order to debug something or focus on a
particular test.

For example, with the generated tests, you can write:

```bash
litexa test happy # will only run the "happy path" test case
litexa test "stuff to work" # you need quotes to use multi-word filter
litexa test r # will run "asking for help" and "stuff to work" because both names contain `r`
litexa test util # will run "stuff to work" because that is the only test located in utils.test.js
```

## When and what should I test?

### The When

You should be designing, iterating, and testing your skill as a feedback
loop. One of Litexa's strengths lies in rapid prototyping. As a result,
your workflow might be in the following order:

* design a primitive user flow or presentation of the
  skill or feature
* iterate on it with actual content and skill
mechanics
  * as a part of implementation, use tests to simulate
    skill mechanics and dialogue with Litexa tests, to
    identify issues and areas for improvement and polish
* test on a real Alexa device
* write regression Litexa tests for the implemented skill or
feature
* optional [beta test](https://developer.amazon.com/docs/custom-skills/skills-beta-testing-for-alexa-skills.html) with a beta pool of customers
* publish skill to skill store
* repeat

### The What

We can divide when to test based on the type of things
to test. Here are some general tips the Alexa Games team has
found helpful.

#### Tests during development iteration

You will get the most value from Litexa tests as a part of
iteration during development from:

* connecting dialogue between states by reading test
  output:
  * are dialogue transitions between states jarring?
  * do dialogue pieces flow well together?
  * this includes transitions to and from global state handlers
* state transitions:
  * is there an interaction flow I can shorten if I save information?
  * am I forgetting to ask for a piece of data?
  * do the triggering conditions for which state to go to
    make sense?

#### Tests to add for long term value

You will get the most value from regression Litexa tests by
writing tests for:

* expected user interaction paths
* things that change between skill sessions:
  * resuming a game after stopping it in the previous
    session
  * time-sensitive dialogue and behavior (e.g if the user last launched
    the skill a week ago, what state do you want to handle
    that launch in)
* edge cases from user input (e.g negative numbers, starting
  over the skill at different points in the state flow,
  unexpected intents or slot inputs)
* one-shot intents (when a user launches your skill with an
  intent)

It may be beneficial to organize and/or name tests by the
feature in the skill they are testing.

#### Code tests to write

You will get the most value from code tests by:

* checking code coverage
* checking edge cases, based on input

#### Things the Litexa test framework can't do for you

There are some things you can't get out of/capture from
offline Litexa tests, and would require testing on a real
device:

* microphone controls:
  * is the specified control appropriate?
  * is it obvious the skill wants user input (e.g dialogue phrasing)?
* how Alexa pronounces/says your speech and audio:
  * dialogue transitions and length
  * there is a limit to audio length and format. Will it
    cause your skill response to fail?
* interaction pacing and length

#### Customer playtesting

There are also things you can't capture without real customer
feedback and playtesting on a real device:

* user experience:
  * how are your users feeling when they interact with your
    skill?
  * how do you gauge ease of use?
  * do your users understand what the skill is asking them
    to do? (i.e voice design)
* really unexpected input:
  * what customers might intuitively say to your skill
  * unexpected bugs in skill mechanics
  * edge cases

## References

### Litexa Test Statements

Litexa adds more syntax and statements for writing tests. They
are listed below with the link to their description in the
[Language Reference](/reference/). We'd recommend reading them
in this order.

* [TEST](/reference/#test)
* [launch](/reference/#launch)
* [alexa:](/reference/#alexa)
* [user:](/reference/#user)
* [LISTEN](/reference/#listen-testing)
* [END](/reference/#end-testing)
* [capture](/reference/#capture)
* [resume](/reference/#resume)
* [database variables](/reference/#variable-testing)
* [quit](/reference/#quit)
* [wait](/reference/#wait)
* [directive:](/reference/#directive-2)
* [setRegion](/reference/#setregion)
* [logStateTraces](/reference/#logstatetraces)
* [request:](/reference/#request)

### Code Test Statements

Litexa adds a Test class that plugs into the test framework.
Its interface is located in the [Inlined Code Test
Reference](/reference/inlined-code-tests.html).

Otherwise, if you'd like to look at the source code for this
test library, go to the `litexa` package's
`src/parser/testing.coffee`'s TestLibrary class.

### .test Directory Contents

Running `litexa test` will generate a .test directory with test artifacts. You
can delete this at any time without affecting your Litexa project. The command
is deployment target specific; the artifacts will live in a subdirectory inside
the `.test` directory, named after the target. If no target is specified,
`litexa test` will default to the `development` target, which is equivalent to
`litexa test -d development`.

However, the contents might be useful for diving deeper into
your test output. Here are all the files and their contents:

* `lambda.js` contains your Litexa-compiled skill code, equivalent to
  what would be uploaded during deployment.
* `libraryCode.js` consists of Litexa utility functions and preamble
  code and does not contain project code.
* `model.json` is the generated skill interaction model, made
  for the region the test command was run in and is not affected by
  `setRegion` statements.
* `output.json` contains the raw skill requests that the test
  statements generated, and the skill responses
  that the skill produced to respond to those requests.
* `output.log` is the same test transcript that was written to your terminal.
* `project-config.json` contains detailed information about your
  Litexa project, including extensions it is using.
* `test.js` is your Litexa-compiled skill code that was run
  locally during the test; it does not contain code the deploy
  module would have added.

Specifically, the `output.json` and `model.json` might be the
most useful files for you to peruse if you want to inspect
your skill response contents. This is probably most useful
for inspecting [directives](https://developer.amazon.com/docs/alexa-voice-service/interaction-model.html#interfaces).

:::warning
If you change your `litexa.config.coffee/js/ts/json` file, the `.test` directory
will be wiped when you next run any `litexa` command from
the command line.
:::
