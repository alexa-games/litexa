# Litexa Language Tour

> NOTE: This is a work in progress, expect plenty to be
> missing. Please yell at surjosub@amazon.com with any
> questions, errata or straight up omissions

The Litexa language is oriented around a few core
goals and ideas:

* It is state oriented: the top level construct in a `.litexa`
  file is a state, and flow control is described as
  transitioning between states.
* Focused on Alexa Skill input, which is to say voice intents
  and events, and Alexa skill output, which is to say speech
  and screens.
* Brevity: a `.litexa` file should contain your skill's unique
  content, and very little else.

Litexa is a white space dependent language like Python
or Coffee Script, which is to say that statements are grouped
using indentation rather than begin and end symbols.

The exact amount of white space doesn't matter, consecutive
statements are considered to be in the same block if they
begin with exactly the same white space. Samples and
tests in this package are written with two spaces for
each indent. In the abstract:

    This is statement 1
      This statement is subordinate to statement 1
      This statement is the same, let's call it X
        This statement is subordinate to X
      This statement is back to belonging to statement 1

Blank lines can be inserted anywhere to aid legibility, they
never have any semantic meaning.

Note, any line that begins with a `#` symbol is considered
a comment and will be ignored by the parser, even if it
is otherwise a valid statement. Likewise, any line containing
a `#` symbol is split in half, with the second part being
a comment too.
You can use this to leave yourself notes, or disable
statements temporarily.


## States

A new state is defined by adding a name on its own line, with
no preceding white space. State names must begin with a letter,
may contain any mix of letters, numbers, and underscores and
can NOT contain any spaces.
`launch`, `doAThing` and `Ask-for-something` are
all valid state names.

A state contains two parts, the entrance code, and the event code.
The entrance code is executed immediately after another state
transitions to it. Event code is executed whenever the skill
is stopped at a particular state, and receives the appropriate
event.

An event is defined by adding a `when` statement to a State,
which then contains all the code subordinate to it.
An entrance is then all statements subordinate to the
state, before the first `when` statement.

Here's an example:

    askForANumber
      say "Hey there, can you give me a number please?"
      reprompt "Just say a number, any number."

      when "how about $number"
        with $number = AMAZON.NUMBER
        say "Great! I love the number $number"

In this case, the name of our state is `askForANumber`. It
contains one `say` and one `reprompt` statement in its entrance
code. It has one event handler, which in turn contains two
statements, one `with` statement and one `say` statement.

State code executes atomically, that is to say an entrance
or event blocks of statements will finish executing completely
before any other Litexa statement will execute: a skill is
always executing exactly one state.

Execution of a skill always begins at the `launch` state, so you
must define it. When you determine the skill should proceed to
another state, you use the `->` or "arrow" statement.

Execution will continue, following arrows, until you hit an
entrance that does not have any arrows. This is called an open
state, and will result in a response being sent to the skill's
user, along with instructions to open the microphone and expect
an answer.

Alternatively, the `END` statement can be used to indicate that
the skill has reached its end, should send the response to the
user and not open the microphone any further.

    launch
      say "welcome, person."
      -> askName

    askName
      say "what is your name?"
      reprompt "please tell me your name"

      when "my name is $name"
        with $name = AMAZON.US_FIRST_NAME
        say "Nice to meet you, $name!"
        END

      when AMAZON.RepeatIntent
        -> askName

      when AMAZON.HelpIntent
        -> askName


In this short skill, we begin at launch, say something then
proceed to the `askName` state. On entering that state we'll
ask a question. Should the question be answered with an
intent, then we'll acknowledge it by saying something and
then end the skill. Should the user instead say "Alexa, help"
or "Alexa, repeat that", we'll reenter the `askName` state,
causing it to ask the question again, and open the microphone.

**Important!** recall that states cannot interleave operation.
This means that arrow statements do not take effect until
the rest of the statements in the same state have been
evaluated; arrows are an instruction for what to do after
the state is complete, not an instruction to execute
immediately. Likewise, the `END` instruction refers to
the course of action to take after this state is complete,
and does not immediately stop execution.


As an example, the following skills would produce the same
response:

    # skill 1
    launch
      say "Hello "
      -> world

    world
      say "World"
      END

    # skill 2
    launch
      -> world
      say "Hello "

    world
      END
      say "World"


## Audio output
An Alexa Skill communicates with its user primarily through
speech. The Litexa command to say something is `say`.

    say "Hello, Alexa user"

You can add white space, including line breaks between the
quotes, which may make longer lines easier to work with.

    say "Hello there Alexa user.
      Glad to make your acquaintance.
      Should we continue?"

Litexa supports a tagging system to add more
information to the speech stream. Tags always begin and
end with the angle brackets, `<` and `>`, are identified
by the first thing written inside them, and sometimes
take additional parameters.

To add pauses in speech, you can normally rely on commas and
periods. For longer or more specific durations, you can use
a `...` tag, which takes a time value as a parameter. You can
specify the time in milliseconds or seconds.

    say "Welcome to the <... 2s> show!"
    say "I see you shiver with antici <...3000ms> pation!"

You can add Alexa interjections, or [speechcons](https://developer.amazon.com/docs/custom-skills/speechcon-reference-interjections-english-us.html),
with the `!` tag.

    say "<!Howdy>, partner!"
    say "I bid you, <!au revoir>."

You can specify audio files with the `soundEffect` statement.
This statement takes a filename, assumed to be in your `assets`
folder.

    soundEffect beepbeep.mp3


All of the `say` and `soundEffect` statements encountered while
executing the state machine are collected and concatenated
together during the next response sent to the user.

    soundEffect dingdong.mp3
    say "Oh, was that the doorbell?"
    soundEffect footsteps.mp3
    say "I wonder who that could be?"


You can add variations to a `say` statement using subordinate
`or` statements. Each time the statement is encountered, a
random variation will be selected, with a strong bias away
from using the same variation consecutively.

    say "Hello there."
      or "Hi there."
      or "Greetings!"

During the course of a skill, you will often need to interpolate
dynamic values into your speech. There are three forms of
built in interpolation available to say statements:

* `@variable` is a reference to a persistent variable
* `$variable` is a reference to a slot variable
* `{ code }` is a call to JavaScript code, including local
  variable references

We'll cover these in detail in other sections, but for now
let's look at an example of how they're used:

    launch
      say "hmm, I think today is { getTodayName() }."
      if @name
        say "Oh, hey there @name. Good to see you again!"
        END
      else
        say "Oh hello there, person I don't know."
        -> askName

    askName
      say "Hey, what's your name?"

      when "my name is $name"
        with $name = AMAZON.US_FIRST_NAME
        say "great to meet you $name"
        @name = $name
        END


## Voice input

Users communicate with Alexa skills primarily through voice
intents. As a skill author, you want to define what you
think a user will say to get a specific outcome, then write
code to produce that outcome.

Intents are defined as events using the `when` statement,
followed by the *utterance* you expect the user to say. As
with the `say` statement, subordinate `or` statements can
be used to define variations you think a user might say
instead.

An intent can be reused in another state by using the same
first utterance in another `when` statement. Sometimes in
these cases it can be convenient to name the intent
separately rather than reusing the first utterance, freeing
you to change the utterance in one spot rather than
in every state it appears in. In this case you can substitute
a name in the `when` statement by omitting the quotation
marks.

    waitForAction
      say "what do we do?"

      when AMAZON.HelpIntent
        # when the built in help intent is received

      when "jump in circles"
        # when the user says exactly 'jump in circles'

      when "lie down"
        or "drop to the ground"
        or "go prone"
        or "duck"
        # when the user says any of these things

      when ENTER_HOUSE
        or "enter the house"
        or "go inside the house"
        or "get in the house"
        # when the user says any of these things

    waitForOtherAction
      when ENTER_HOUSE
        # when the user says anything from the list
        # of utterances defined for ENTER_HOUSE above


As part of an utterance, you might expect a segment that could
have one of many values. These are called *slots*. See the
[ASK documentation](https://developer.amazon.com/docs/custom-skills/slot-type-reference.html)
for a deep dive into these.

In Litexa, slots are placed into an utterance
using the `$` symbol, and their type is defined using a `with`
statement. In the code for the event, the slot is then
available as a variable.

    askForName
      say "What is your name?"

      when "my name is $name"
        with $name = AMAZON.US_FIRST_NAME

        # use the value of the slot to say something
        say "Hello there, $name"

        # store the slot value for later
        @username = name

Should you require a custom slot, that is to say a slot that
expects values from a list you define, then you will need to
write a *slot builder function*, a function that returns
a list of values. To refer to a specific slot builder function
you set it as the type for the slot.

    askForColor
      say "which color would you like?"

      when "I'd like $color"
        with $color = slots.build.coffee:colorNames
        say "oh, I suppose I like $color too. Good choice"

In this example, the values for the `$color` slot will be
defined by the function named `roomNames` exported by file
`litexa/slots.build.coffee` Here's an example of what that
file might look like:

    exports.colorNames = (skill, language) ->
      return ['COLORNAMES', [ 'red', 'blue', 'green'] ]

In this example, the colorNames function returns the definition
for a slot called `COLORNAMES` that specifies three possible
values.


## Variables

There are three kinds of variables in Litexa.

* `@variables`, those beginning with the `@` symbol, are
  permanent variables, stored in your skill's
  database, surviving from skill session to skill session.
* `$variables` are the contents of slots, and only exist during
  the statements directly following a `when` statement.
* regular `variables` can be one of two things:
  * values defined in your inline code files
  * values defined locally in the current event

You can assign the value of a variable with the `=` *assignment*
operator.

    @name = Bob
    @age = 13
    @rememberThis = $aSlotValue

The right side of the assignment operator can be any valid
expression. See the [Expressions](#Expressions) section for more details.

There are several types of values a variable might have:

* a string, or a list of characters, e.g. `"Jane"`
* a number, e.g. `6` or `439.8`
* a boolean, i.e. either `true` or `false`
* specifically nothing, i.e. the value `null`

A variable that has never been defined before will have the
special value `undefined`, rather than `null`

All values have a *truthiness* value, meaning that when they
are used in a place that expects a true/false value, they
can stand in for either true or false. The number `0`, the values
`null`, `undefined` and the empty string `""` are all considered
false. All other values are considered true.

You can create temporary variables anywhere with the `var`
statement. You can use these as temporary value stores between
statements, but they will disappear at the end of the current
event. These temporary variables *must* be initialized to some
value when they are created.

Regular variables can be interpolated into strings using the
curly bracket notation, including accessing members of
objects built in your code files.

    reportUser
      local user = getCurrentUser()
      say "The user's name is { user.name }, they are
        { user.age } years old"

## Flow Control

Litexa has an `if` - `else` structure to
define simple branches in your code. All statements subordinate
to the `if` clause will only execute if the condition is
true, otherwise the statements subordinate to the `else`
clause will take place.

The conditional portion of the `if` clause can compare numbers,
strings and boolean literals, to any kind of variable and or
the result of function calls. See the [Expressions](#Expressions)
section  for a deeper look at the possibilities here:
the comparison portion can be any expression, with any
value other than true or false being checked for *truthiness*

You can chain exclusive conditions by inserting in `else if`
clause between the `if` and `else` clauses.

    if @name == "Bob"
      say "Oh it's you, Bob"
    else if @name == "Jane" and @lastName == "Spellman"
      say "Hey Jane, good afternoon"
    else
      say "I don't recognize you."


For more complex branching, you may want to use the `switch`
statement. This statement supports a number of optional
features.

The simplest form expects you to give it a value as part
of the `switch` statement. Subsequent subordinate statements
then each begin with a comparison against that value, followed
by the `then` keyword. Each `then` statement begins a new
block of subordinate statements that will execute when the
condition is true. Note: only one `then` clause will be
executed, the first to be true when checked top to bottom.
Optionally an `else` statement can be added, which will
be executed if all `then` statements prove to be false.

    switch $diceValue
      == 1 then
        say "bad luck, that's a 1"
      < 5 then
        say "good enough, you pass!"
      else
        say "wow! you're like the luckiest person"

For more complex string matching scenarios, you can use
a full regular expression by using the `match` operator.

    switch $name
      match /bob|greg/i then
        say "Hello fellas"
      match /jane|maria/i then
        say "Hello ladies"
      else
        say "Hello friends"

Regular expressions are in the JavaScript format, and
can include the trailing `i` flag to indicate that
matches should be (ASCII) case insensitive.

Each `then` statement can be preceded by any valid
expression, and the `switch` statement supports omitting
the initial value. In this way, you can rewrite a long
set of `if` - `else if` statements as a `switch` instead

    switch
      @name == "Bob" then
        say "Oh it's you, Bob"
      @name == "Jane" and @lastName == "Spellman" then
        say "Hey Jane, good afternoon"
      else
        say "I don't recognize you."

The `switch` statement can also optionally bind more than
one named variable, all of which will only be valid
for the duration of the `switch` statement

    switch a = getFirstAge(), b = getSecondAge()
      a == b then
        say "Oh! You're the same ages!"
      a > b then
        say "B, you're older, aren't you?"
      b < a then
        say "A, you're the older one."

## Expressions

Expression appear in a number of places in Litexa,
like in the conditional parts of flow control statements
and on the right side of variable assignment.

An expression is any combination of variable references,
combinatory operators, function calls and braces to
control order.

The mathematical operators `+`, `-`, `*` and `/` are available
for working with numbers

    local a = 5 + 1
    local b = a / 3
    local c = a + ( b * 4 )

Additionally the `+` operator also combines strings

    local a = "Hello" + " " + "World"

The `>`, `>=`, `<`, `<=`, `==` logical operators produce
boolean values, along with the `~=` equals operator. Boolean
values can be combined with the `or` and `and` operators.

    local a = 5 > 6
    local a = 2 < val and val < 10
    local a = ( 2 < val and val < 10 ) or val == 100

You can call any function you've defined in your inline
code files directly from a Litexa expression, they
are defined in the same scope. You can also call functions
bound onto any objects you retrieve in that way.

    local person = getPersonTalking()
    local name = formatPersonName( person )
    say "Hello there, { person.getFullName() }"

## Cards

Litexa has built in statements to produce Alexa
companion app cards.

    card "Hello World", flowers.jpg, "This is a good day to
      meet you, person."

    card "Hello World", flowers.jpg

    card "Hello World", "This is a good day to
      meet you, person."

    card "Hello World"
      image: flowers.jpg
      content: "This is a good day to meet you, person."

For cards, you're specifying 3 things: a title, an image
and some text. You can optionally specify the image and
content on their own lines as properties if the statement
is getting too long winded to read easily.

Variable interpolation is supported in the same manner
as with the `say` statement.

    card "Hello @name", flowers.jpg
