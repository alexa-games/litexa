# State Management and Intent Routing

## Why State Management?

Let's first clarify what we mean by state. During the execution
of an Alexa skill, you'll find that the top level structure is
as such:

1. User says something
2. Alexa says something back. If it's a question, goto 1
3. End skill

What Alexa chooses to say in 2, clearly depends on what the user
said in 1, but what the user says next in 1, they say in response
to the question asked in 2. This means that in order for your
skill to produce the right Alexa speech, you need to know at least
both what the user said *and* what the last thing Alexa asked was.
In practice, long form skills will usually need to remember at
least a few more things.

The totality of data that represents that memory is what we call
the *Current Skill State* and Litexa's syntax is designed around
this central idea of handling incoming intents based on that
state.

## Litexa States

To define the "where are we in the conversation" part of the skill
state, Litexa groups code statements into named blocks also called
*states*, which are further subdivided into three kinds of blocks
called *handlers*:

1. the **entry handler**, executed when a state first becomes active
2. a set of **intent handlers**, executed when the skill receives any
   a specific intent, while the state is active
3. **the exit handler**, executed when a state has just become inactive,
   before the next state becomes active.

A few specific statements in the Litexa language apply to
the skill at all times, and as such they are found outside the
scope of any state. These are called *global statements*.

Here's a look at the syntax for defining these parts:

```coffeescript
# global statements would go here

stateName
  # all code placed here constitutes the "entry handler" for
  # this state

  when "do something"
    # when the skill is in this state, and the user says
    # "do something", then this intent handler will execute

  when AMAZON.YesIntent
    # you can use built in Alexa intent names directly, in
    # this case the AMAZON.YesIntent which specifies various
    # ways a person might say "yes" in the current language

  otherwise
    # code here will be run should an intent matching none
    # of the above handlers is received while the skill is
    # in this specific state

  # all code placed here constitutes the "exit handler"
  # no more intent handlers can be defined after this point


anotherStateName
  # this began a new state
```

## State Flow

When a skill begins, the skill is always set to be in the `launch`
state, that is the state named exactly "launch", and will always
run that state's entry handler.

When a handler completes, it must choose to do one and only one of
three things, each specified by a statement:

1. It can choose to end the current state and activate a new one,
with the `-> stateName` *state transition statement*
2. It can choose to stop the state machine in the current state
and send the current results to the user with the `LISTEN` statement.
3. It can choose to end the skill, returning all final results
to the user with the `END` statement.

The `LISTEN` statement additionally takes arguments aimed at the
user's device. Currently you can specify:

1. `LISTEN microphone` to open the blue ring and microphone to accept
  user voice commands
2. `LISTEN` or `LISTEN events` to send no specific commands to the
  user device, keeping the session open but NOT opening the microphone

In any case though, an Alexa skill should always expect any kind of
event to appear, so neither of these variations restrict what kinds
of events will appear next. E.g. even without sending `LISTEN microphone`
a skill must be prepared to handle the user using the wake word
to say something, e.g. "Alexa, help".

::: tip Note
Each handler will completely finish before any other handler can
run, and each handler will completely finish before a skill returns
a response. This means that a Litexa skill, for a given user, will
only ever be in *one state at a time*, and that the code can determine
where to resume the skill by storing just the name of the state we last
stopped at.
:::

Let's look at a sample in action:

```coffeescript
launch
  say "Hello!"
  -> askAboutRoses


askAboutRoses
  say "Which do you prefer, red or blue roses?"
  reprompt "No really, do you like red, or blue roses better?"
  LISTEN microphone

  when "I like $color roses"
    or "$color ones"
    or "$color, I guess"
    or "$color"
    with color = "red", "blue"

    say "Hey, I like $color ones too."
      or "How about that. I like $color ones too."
    say "Goodbye"
    END

  when AMAZON.HelpIntent
    say "Please tell me, do you like red, or blue roses?"
    LISTEN microphone

  when AMAZON.RepeatIntent
    -> askAboutRoses

  otherwise
    say "I'm sorry, didn't catch that."
    -> askAboutRoses
````

We begin at launch, presumably after the user has said something
like "Alexa, launch roses". The launch state's entry handler
greets the user, and then uses a state transition to go to the
`askAboutRoses` state. That state's entry handler asks the
question, then finishes with a listen statement. This causes
the skill to return all say statements, ask that the microphone
be opened, and begin listening for incoming events.

Let's look at a run through of the skill to understand how the
rest of the handlers work out:

```yaml
 user: alexa, launch roses
alexa: Hello! Which to you prefer, red or blue roses?
 user: repeat that
alexa: Which do you prefer, red or blue roses?
 user: help
alexa: Please tell me, do you like red, or blue roses?
 user: blue, I guess
alexa: How bout that. I like blue color ones too! Goodbye
```

Once you are comfortable with the role of the `LISTEN microphone`
statement, you may drop it entirely: a handler that does not
specify an ending will default to ending with `LISTEN microphone`!


### When does a state transition happen?

It's important to note that while the three statements we've
described here determine what happens when a handler ends, they 
do not themselves terminate the handler, nor are their 
effects immediate. For example:

```coffeescript
askAboutSomething
  say "what is the capital of France?"

  when "I think it's $city"
    with $city = "paris", "rome", "london"

    if $city == "paris"
      -> correctAnswer
    else
      -> incorrectAnswer

    say "you said $city, <...1s>"
    @lastAnswer = $city

correctAnswer
  say "That's the right answer!"

incorrectAnswer
  say "I'm afraid that's the wrong answer"
```

In the above sample, the order of speech if the user answered
correctly will be: *"you said $city, <...1s> That's the right answer!"* 
because the transitions don't happen until *after the handler 
is complete*.

You may want to read `->` as *queue a state transition* rather 
than a *change state now* function. The statement could be 
replaced before the end of the handler, or even recinded if an
END statement is encountered after it. This is an important part
of the design of the state machine, and produces the following 
effects: 

* there is only ever the active state, there is no stack of 
  states to return to. As such, there are no restrictions on 
  the topology of of the state graph, a set of states can 
  (and often do) sit in one or more interlocking infinite 
  loops, a requirement for open ended interaction.

* states are not responsible for what happens downstream, and 
  have no parent state to consider. Any state in a loop can 
  choose to break it, for instance, without consequence to the
  integrity of the state machine. This also means global code
  can choose to transition anywhere in the state machine without
  unwinding a call stack first.

* there are no side effects from the execution of other handlers,
  during the execution of a single handler. After entering a state,
  the exit handler for a state will always be run before any 
  other state's code is run. If this were not the case, given that
  any handler can prompt the next turn with `LISTEN`, 
  supporting mid handler execution of other state's code could 
  mean that that one or more dialog turns could have happened during 
  the handler; an intent handler could find itself no 
  longer handling that intent!

Simplifying this underlying primive it a key part of the Litexa 
design philosophy, with the intention of making easy to understand
promises on how to reason about a program's execution: at any given
moment the current position of the skill is only ever in one state,
and only the code in that state will decide what happens next.

It's entirely possible though, to build more complexity on top of 
these primitives. Things to consider:

* Business logic is often better expressed in your code language 
  of choice, e.g. JavaScript. If you need an immediate effect 
  mid handler, is it something that belongs in code?
* States can be useful as just combinatorial flow paths, they 
  don't have to reflect request/response stopping points. If you 
  find yourself needing an immediate effect mid handler, could you 
  perhaps split the handler up into a series of states to 
  transition between?
* You can service return paths and future branching using global 
  variables and conditionals. This pattern shows up in "aside"
  flows, e.g. asking for help where you may transition to a series
  of help states, then want to "come back" to what you were doing.
  You could maintain a `@currentActivity` variable at all times, and 
  then write a `returnToCurrentActivity` state that knows how to switch
  routing based on it. This would let you "interrupt" a 
  current activity at any time, and then "blindly" return to the 
  current activity from anywhere.

::: tip Note
The three state transitions statements `->`, `END`, `LISTEN` all 
overwrite each other, e.g. you can issue an `END` after a `->` in the 
same state, and you'll effectively have cancelled the transition.
:::

## Intent Handlers

### Intents and Utterances

Let's deep dive on the `when` statements we've seen pop up. A
when statement begins an intent handler, and defines what kind
of event the handler will be invoked in response to. When
followed by a quoted string, the statement defines a spoken user
intent, which can be followed by any number of `or` statements
to provide variations that should invoke the same handler.

:::tip Note
If you're unfamiliar with the Alexa concepts of intents, slots,
and utterances, you may want to take a moment to brush up at
the [Alexa Documentation on Interaction Models](https://developer.amazon.com/docs/custom-skills/create-the-interaction-model-for-your-skill.html)
:::

```coffeescript
askAQuestion
  say "What should we do?"

  when "go to the attic"
    or "check out the attic"
    or "look in the attic"

    say "Alright, heading upstairs."
    -> checkOutAttic

  when "go to the basement"
    or "what's in the basement?"
    or "how about the basement?"

    say "If you say so."
    -> checkOutBasement
```

This fragment would contribute two new intents to an Alexa
skill, automatically named `GO_TO_THE_ATTIC` and `GO_TO_THE_BASEMENT`,
each with a variety of utterances.

You can optionally provide an explicit name for your intents, with
which you can recycle their use in other parts of your skill
without repeating their whole definition.

```coffeescript
idling
  say "What should we do?"

  when AttackEnemy
    or "attack the enemy"
    or "swing my weapon"
    or "swing the sword"
    say "Heave!"
    -> askCombo

askCombo
  say "What do we follow up with?"

  when AttackEnemy
    say "You know that thing is heavy, right? Fine."
    -> doubleAttack
```

Where you have utterances that are permutations of a single
grammar, you can use inline alternation to generate them. You can
mix and match inline alternation with the `or` statement to compose
a full intent.

```coffeescript
idline
  when AttackEnemy
    or "swing (my|the) (weapon|sword) (at the enemy|)"
    or "(attack|kill) the enemy"
    # this produces 10 utterances, including "swing my sword"
    # "kill the enemy", and "swing the weapon at the enemy"
```


Finally, as Alexa will dutifully recognize any utterance across
your entire language model at any time, a skill must be prepared
to handle any intent while waiting in any state. To capture intents
you don't expect for a given state, you can use the `otherwise` statement.
Given that we're not distinguishing between which intent
is coming in for the state, it's usually best to treat the
otherwise case as a failure to understand the player's actual
intent, and redirect them back into the skill's flow.

```coffeescript
askAQuestion
  say "What should we do?"

  when "go to the attic"
    say "Alright, heading upstairs."
    -> checkOutAttic

  when "go to the basement"
    say "If you say so."
    -> checkOutBasement

  otherwise
    say "I'm sorry, I didn't catch that. What
      do you think we should do next. Go to the
      attic or go to the basement?"
```

### Slots

Slots are variable parts of an utterance, where you expect
a user to say any of a specific set of words in their place.

In Litexa we define a slot with a variable name starting with
the `$` character. You must then specify the type of slot using
the `when` statement, after all of your utterances.
The slot value will be accessible in the proceeding handler
using the same variable name.

```coffeescript
idling
  say "What should we do?"

  when "Pick up the $thing"
    with $thing = "rope", "bird", "cage"

    say "Ok, you have the $thing"
```

Here we have state that defines a single intent, with a single
slot named `$thing`. We define `$thing` as one of a list of
possible words: rope, bird, or cage. In the handler, we can use
the same $thing and assume it contains whatever the user said.

:::warning Beware Large Slots!
Alexa does not guarantee that the word that comes
in a slot will necessarily be exactly one of the words you
define for the slot. In particular, slots with many entries can
and will start to pick up other user speech, if the rest of the
sentence matches one of the utterances very well.
:::

Behind the scenes, the slot we automatically created from that
list was named thingType. We can recycle the same list elsewhere
in our skill:

```coffeescript
  when "Eat the $thing"
    with $thing = thingType

    say "Nope, you can't eat a $thing"
```

If we need slot value lists that are too unwieldy to specify
with this syntax, we can instead fall back to a code function
to generate them. In that case, we'll refer to a file in the
`litexa` directory, and a function to use from that file.

```coffeescript
  when "plant a $plant"
    with $plant = slotbuilder.build.js:plantSlots

    say "Alright, let's get a $plant going."
```

In `litexa/slotbuilder.build.js` we'd then need to define a function
to return the new slot name and its values. The function will
be called with the litexa parser's skill object, and the
litexa language being parsed. We then assign that function to `exports`.

```javascript
// litexa/slotbuilder.build.js
function plantSlots(skill, language){
  return {
    name: "plantTypes",
    values: [ "cucumber", "zucchini", "potato", "eggplant", "tomato" ]
  };
}

exports.plantSlots = plantSlots;
```

We can take advantage of Alexa's built in synonym mapping by
returning an object with the full slot definition. We can also
mix and match the short form string with the longer object
definition.

```javascript
function plantSlots(skill, language){
  return {
    name: "plantType",
    values: [
      'cucumber',
      'potato',
      'tomato',
      {
        id: 'eggplant',
        name: {
          value: 'eggplant',
          synonyms: ['aubergine']
        }
      },
      {
        id: 'zucchini',
        name: {
          value: 'zucchini',
          synonyms: ['courgette']
        }
      }
    ]
  }
}

exports.plantSlots = plantSlots;
```

The slot building function is executed in the litexa inline
context, so functions and data you've defined there,
including the [jsonFiles](/reference/#jsonfiles) object,
are available for use.

It is often convenient to iterate over your skill's data to
collect values for your slots, e.g. in a quiz you may collect
the answers to all your questions. When you do so, be careful
to follow [the Alexa guidelines for slot values](https://developer.amazon.com/docs/custom-skills/create-and-edit-custom-slot-types.html#custom-slot-type-values)
You may find you need to sanitize your slot values by removing
unnecessary punctuation.

Let's assume we have a data file at `litexa/questions.json`

```json
[
  {
    "q": "For which film did Angelina Jolie win an Oscar, in the year 2000?",
    "a": "Girl, Interrupted."
  },
  {
    "q": "What are little boys made of?",
    "a": "Snips and snails, and puppy dogs tails."
  }
]
```

We could then extract a slot for answers with the following
code in `litexa/slotbuilder.build.js`

```javascript
// litexa/slotbuilder.build.js
function answerSlots(skill, language){
  let answers = jsonFiles['questions.json'].map( (d) =>
    return d.a.replace(/[,.]/g, ' ');
  );
  return {
    name: 'answers'
    values: answers
  }
}

exports.answerSlots = answerSlots;
```

### Oneshot Intents

A "oneshot" is when an Alexa user bundles an intent into their 
launch utterance, e.g. *"Alexa, ask The Great Psychic to read runes"*.
In the case where the user has a *"The Great Psychic"* skill enabled, 
it would get launched, and immediately presented with its *"read runes"* 
intent as part of the same request.

Normally, the Litexa flow is to deliver any incoming intents into
the currently active skill, then follow any state transitions running
exit and entry handlers, until a response is triggered, and then 
wait for the next incoming intent.

In the case of a oneshot intent, there is no current state yet, so 
Litexa will initialize the session by running the `launch` state's entry 
handler *before* processing the incoming intent. This lets a skill 
keep all its session initialization code in one place. Note, this means
that you can redirect skill flow in the intent handler. In the following
example, the skill normally goes to state `askForActivity` at launch
but on receiving `READING_INTENT` will go to `readRunes` instead.

```coffeescript
launch 
  # this code always runs at skill launch
  say "Welcome to the Great Psychic!"

  # by default we'd usually do this transition at a skill launch
  -> askForActivity

  when "read runes"
    # this code runs if launch also had the intent
    # this state transition overrides the one above, as intent 
    # handlers always come after the entry handler 
    -> readRunes

  otherwise 
    # we'll acknowledge we (mis)heard something here, but otherwise
    # continue with the standard flow
    say "I didn't understand that."

  # code in the exit handler would be run no matter which way we go


askForActivity
  say "What should we do next? I could start a seance, or perhaps
    read the runes?"

readRunes
  soundEffect runes-clacking.mp3
  say "Oh, how interesting!"
  # etc
```

