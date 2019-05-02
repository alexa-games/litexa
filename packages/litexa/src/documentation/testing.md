# Litexa Testing

The Litexa package comes with support for testing your
logic offline. You can simulate invocations of your handler
with a simple scripting language, and test your js/coffee code
with a basic test harness.

For more details about testing, please see the Testing
chapter of The Book.

## Running the tests

At any time, you can execute the command `litexa test` in your
project directory to have all the tests in your project run
and print a report to the command line.

When you do this, a `.test` directory is also created, with
a full report of all the output, and intermediate artifacts
like the full skill JavaScript function to inspect.

To have the test watch for file changes and re-run itself, you
can add the `-w` flag to the command, i.e. `litexa test -w`

You can also narrow down the tests that get executed, by providing
a text filter. This will attempt to match the name of the file that
the tests are define in, or the name of the individual tests.
Matches are fuzzy, so `litexa test first` will match all tests
in the `the-first.test.litexa` file.

## Skill tests

You can define a skill test in any `.litexa` file. If you'd like
to create a file specifically for testing, name it `.test.litexa`
instead.

A test begins with the `TEST` statement, which is followed by a
name.

Subsequent lines in turn actions and expected outcomes. The first
action is usually the `launch` statement, which simulates a
new launch intent.

Subsequently, the `user` statement defines what the user says,
while the `alexa` statement defines what state we expect the skill
to be in after that action, and optionally what we expect Alexa
to say.

Here's an example.

    TEST "cold launch"
      launch
      alexa: askName, "<door-bell.mp3> Greetings friend. What is your name?"
      user: "it is Bob"
      alexa: null, "Nice to meet you Bob, goodbye."
      END

In this test, we expect alexa to be in the state `askName` after
launch, and for her to say exactly that line. Subsequently, if
the user says "it is Bob", then we expect Alexa to be in the
state `null`, or terminated, and we expect her to say the line,
and finally we expect the session to have ended with the `END`
statement.

The `alexa` statement can omit the output speech if we don't need
to assert its exact contents, and the user statement can specify
an intent name directly instead. So we might see

    TEST "asking for help"
      launch
      alexa: askName
      user: AMAZON.HelpIntent
      alexa: askName
      user: "I'm Bob"
      alexa: null
      END

Here we didn't care exactly what was said, we're just interested in
making sure that a query for help would result in the skill returning
to the askName state, and that the skill would continue as expected.

You can run through this test interactively in the console by using
the command `litexa interactive`, and typing in each of the statements.

## Code tests

Any file with the extension `spec.js/test.js/spec.ts/spec.coffee/test.coffee`
in the `litexa` directory will be assumed to contain code
tests.

Inside a code test file, you can assume that a library exists in
scope called `Test`.

Each named test begins by calling the `expect` function on the `Test`
object with a name, and a function to evaluate.

Inside the function, you'll use functions on the `Test` object to
assert requirements. The `equal` function tests for value equality,
while the `check` function takes a function that should return
`true` or `false` for its success. To log outputs, you can use the
`report` function.

Here's an example:

    Test.expect "stuff to work", ->
      Test.equal typeof(todayName()), 'string'
      Test.check -> addNumbers(1, 2, 3) == 6
      Test.report "today is #{todayName()}"
