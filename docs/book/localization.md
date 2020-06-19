# Localization

Litexa features support for localizing your skill for [multiple
locales](https://developer.amazon.com/docs/custom-skills/develop-skills-in-multiple-languages.html#h2-code-changes).
You can localize your skill in 2 ways:

* project structure-based overrides
* string replacement map

## Skill Manifest changes

To add your skill in multiple locales, you first need to declare that locale in
your `skill.js/ts/coffee/json` file. The default generated project sets up your
skill manifest object for 'en-US' like so:

```javascript
{
  manifest: {
    publishingInformation: {
      isAvailableWorldwide: false,
      distributionCountries: ['US'],
      distributionMode: 'PUBLIC',
      category: 'GAMES',
      testingInstructions: 'replace with testing instructions',
      locales: {
        'en-US': {
          name: 'Cat Chase in Space',
          invocation: 'cat chase in space',
          // ... more fields
        }
      }
  ...
```

All other locales will contain the same fields as in 'en-US', so you can copy
the existing contents over to the other locale and then modify its values.

:::tip Distribution Countries
There is a field in the manifest called 'distributionCountries,' which is *not*
related to individual locales supported in your skill. This field instead
affects your skill's availability in select regions. For more information, read
the [distribution
documentation](https://developer.amazon.com/docs/custom-skills/develop-skills-in-multiple-languages.html#h2-distribution).
:::

Now, you can proceed with one of the localization methods.

## Option 1: Project Structure-based Overrides

This localization method is best suited for:

* few changes to dialogue (e.g default skill is 'en-US' and localized skill is 'en-GB')
* assets
* functionality changes per locale (e.g monetization not available in some
  locales yet)

### Project Structure

Let's review your existing Litexa project's structure. In the `litexa` directory
are `.litexa` files, an `assets` directory, and some code files. These contents are
known as your **default skill code**. This means that unless your skill contains
localization, it will use the content in these files.

To localize your skill using this method, create a `languages` directory under
the `litexa` directory. Then, for all locales you will be supporting, create a
directory named after the locale inside the `languages` directory. From there,
for whichever content changes that differ from the default skill (e.g contents
of `.litexa` files in `litexa` directory), mirror the project structure of the
default skill inside the target locale directory.

For example, here is what a project structure may look like if the skill
contains content overrides for 'en-GB' and 'de' (assuming that the default skill
is written for 'en-US'):

```
.
├── README.md
├── artifacts.json
├── litexa
│   ├── assets
|   |   ├── intro.mp3
│   │   ├── icon-108.png
│   │   └── icon-512.png
│   ├── main.js
│   ├── main.litexa
|   ├── tutorial.litexa
│   ├── main.test.litexa
|   ├── slotbuilder.build.js
|   └── languages
|       ├── de # create a locale directory here
│       |   ├── assets
│       |   |   └── intro.mp3
|       |   ├── slotbuilder.build.js
│       |   ├── main.litexa
│       |   └── tutorial.litexa
|       └── en-GB # create a locale directory here
│           ├── assets
│           |   └── intro.mp3
|           ├── slotbuilder.build.js
│           └── main.litexa
├── litexa.config.js
└── skill.js
```

Here, you can see that running the skill in 'en-GB' will:

* override the `intro.mp3` asset (any reference will play the localized file)
* override contents of `main.litexa` and `slotbuilder.build.js` with the localized files
* use the default `tutorial.litexa` (because there is no localized counterpart)

Running the skill in the 'de' locale will behave similarly, with the exception
that it will override `tutorial.litexa` with the localized file (which is
meaningful because it is a different language).

:::tip Specifying language instead of locale code
Although your skill manifest needs to conform to the [list of
locales](https://developer.amazon.com/docs/custom-skills/develop-skills-in-multiple-languages.html#h2-code-changes),
in the Litexa project structure you can choose to use the first 2 letters of the
locale code if you don't need to differentiate between regions.

For example, if you want to have a uniform French language skill experience, you
will still need to have separate 'fr-CA' and 'fr-FR' fields in
`skill.js/json/ts/coffee`, but you can have a single 'fr' locale directory that
will apply to both locales.
:::

Now that we've seen where to place localized files, let's take a look at writing
localization content. Litexa localization works by overrides - meaning that
unless override content exists for a locale, it will use the default skill
code's content. In Litexa, you can override states and assets.

### State Overrides

Litexa allows you to override skills using states as the unit of change. This
means that any logic and handlers of that state will be overridden by the
localized one. To override a state, simply write the new state logic with the
same name. For example, let's say your default skill code's `main.litexa` looks
like this:

```coffeescript
launch
  say "Hello! How many people are playing today?"
  -> waitForPlayers

waitForPlayers
  when "$count players"
    or "we have $count players"
    with $count = AMAZON.PLAYERS
    if $count < 5 and $count > 1
      say "Great. You have $count players in this game."
      -> playGame
    else
      say "I'm sorry, but we will need between 2 and 4 players to play. How many will be playing today?"
```

Then, suppose in 'en-GB' you want to localize the interjection and limit the
number of players the game can play. Your override `main.litexa` may look like
this:

```coffeescript
waitForPlayers
  when "$count players"
    or "we have $count players"
    with $count = AMAZON.PLAYERS
    if $count < 4 and $count > 1
      say "Brilliant. You have $count players in this game."
      -> playGame
    else
      say "I'm sorry, but we will need 2 or 3 players to play. How many will be playing today?"
```

Note that the localized file does not have a `launch` state. Therefore, the
'en-GB' version of the skill will use the default skill's `launch` state code.

:::tip Match .litexa file names for clarity
Since Litexa overrides `.litexa` content by state names instead of file names,
you could theoretically name your localized `.litexa` files differently from their
default counterparts. However, we strongly recommend matching the file names for
organizational clarity.
:::

#### Skill Model Overrides

You can use the state override functionality to change your skill model as well.

Let's modify the override from the example above.

**Utterances**

Assuming that the COUNT_PLAYERS intent is solely used in the waitForPlayers
state, the following replacement will change the utterances in the 'en-GB' skill
model:

```coffeescript
waitForPlayers
  when "$count players"
    or "playing with $count people"
    with $count = AMAZON.PLAYERS
  ...

```

The default skill model contains this:

```json
...
    "intents": [
      {
        "name": "COUNT_PLAYERS",
        "samples": [
          "{count} players",
          "we have {count} players"
        ],
        "slots": [
          {
            "name": "count",
            "type": "AMAZON.NUMBER"
          }
        ]
      },
...
```

The 'en-GB' skill model will change that intent to:

```json
...
    "intents": [
      {
        "name": "COUNT_PLAYERS",
        "samples": [
          "{count} players",
          "playing with {count} people"
        ],
        "slots": [
          {
            "name": "count",
            "type": "AMAZON.NUMBER"
          }
        ]
      },
...
```

:::tip Utterance aggregation
Utterance aggregation for the same intents across multiple states also follows
the override logic. If the COUNT_PLAYERS intent was also handled in a different
state and contained more sample utterances, and there was no change to the
handler in that state for localization, the 'en-GB' skill model would then
aggregate the 'en-GB' waitForPlayers state's COUNT_PLAYERS utterances with the
ones in the other state of the default skill for the skill model.

Please take a look at the [Intent Handlers
section](/book/state-management.html#intent-handlers) of the State Management
Chapter for more information about intents and utterances.
:::

**Slots**

Suppose you want to change the values of the the custom slot type defined in the
function in `slotbuilder.build.js`. The only thing you'd need to do is define
your localized slots in the locale folder, and Litexa will automatically use
that one for that skill locale. In the example above, you can see that there is
a `slotbuilder.build.js` file inside the 'en-GB' directory to fulfill this
purpose. See [Slots](/book/state-management.html#slots) for how to define custom
slot types.

**Intents**

Because overrides use states as the single unit of change, you can remove and
add intents from/to your model. For example, if you have a quiz skill that asks
different categories of questions, but you want to change one of the categories
in a different locale, you can override the state(s) that contain the relevant
category-specific intents. If your default skill code contains:

```coffeescript
waitForAnswer
  when AnimalsIntent
    or "the animal is $animal"
    with $animal = animals.build.js:slotBuilder

  otherwise
    say "Here is your question again."
    ...
```

You can overwrite that state's handler with:

```coffeescript
waitForAnswer
  when PlantsIntent
    or "the plant is $plant"
    with $plant = plants.build.js:slotBuilder

  otherwise
    say "Here is your question again."
    ...
```

The overridden locale's skill model will then have a PlantsIntent instead of an
AnimalsIntent, with the custom slot type built from the function in
`plants.build.js`.

Let's say you want to remove this category entirely from the localized locale.
To do so, remove any `-> waitForAnswer` transition statement and its relevant skill flow logic.
Then, make this state empty:

```coffeescript
waitForAnswer
  # do nothing
```

Then, your target locale's skill model would no longer include AnimalsIntent.

### Asset Overrides

Much like slots, asset overrides are a one-to-one replacement based on whether
they exist in the locale-specific directory's assets directory or not. This
means that any asset references in the skill will use a localized asset over the
default counterpart. To see the directory structure of assets in the deployed
skill, see the [S3 Configuration section](/book/deployment.html#s3-configuration)
in the Deployment Chapter.

## Option 2: String Replacement Map

This localization method is best suited for:

* minimal functional differences
* major dialogue differences

between supported locales.

This localization method is similar to traditional localization methods -
meaning that all translated strings are aggregated and stored by reference
in a single file, instead of integrating with the skill code.

In this method, we reuse the definition of **default skill code** defined in the
previous method under the [Project Structure](#project-structure) section.

:::tip Note
This method only localizes utterances and say/reprompt strings. Strings in code
are not captured; if you use slot builders, or inline
code speech injection, you will need to do the localization in the same location.

See [Localization in code](#localization-in-code) for details on implementing this.
:::

:::warning
Inline slot definitions (e.g. `with $color = "red", "yellow", "blue"`) do not get
localized with this method.
:::

To localize your skill with this method to a new language, there are 2 steps.

First, you will need to generate a
`localization.json` in your project root via the Litexa command line:

```bash
litexa localize
```

The second step is to create a Litexa file for your target language. This file
can be blank; it just has to exist for Litexa to recognize that you are
supporting that language. So, for example, if you are localizing for French,
you could create `litexa/languages/fr/blank.litexa` and this would complete your
setup. Make sure this conforms to the [project structure](#project-structure)
above.

### The localization file: `localization.json`

You are now ready to add localization content. Let's take a look at the
`localization.json` file. This will serve as the source file for your
translations. This is what it looks like from running it on the vanilla
`litexa generate` skill:

```json
{
  "intents": {
    "AMAZON.StopIntent": {
      "default": []
    },
    "AMAZON.CancelIntent": {
      "default": []
    },
    "AMAZON.StartOverIntent": {
      "default": []
    },
    "MY_NAME_IS_NAME": {
      "default": [
        "my name is {name}",
        "call me {name}",
        "{name}"
      ]
    },
    "AMAZON.HelpIntent": {
      "default": []
    }
  },
  "speech": {
    "Hello again, @name. Wait a minute... you could be someone else.": {},
    "Hi there, human.": {},
    "What's your name?": {},
    "Please tell me your name?": {},
    "Sorry, I didn't understand that.": {},
    "Nice to meet you, $name. It's a fine {todayName()}, isn't it?": {},
    "Just tell me your name please. I'd like to know it.": {},
    "Please? I'm really curious to know what your name is.": {},
    "Bye now!": {}
  }
}
```

`localization.json` follows this structure:

```json
{
  "intents": {
    "SomeIntentName": { // map of all skill intents to their utterances by Litexa language
      "default": [ // utterances parsed from the default Litexa files
        "default utterance {slot_name}",
        "another default utterance {slot_name}"
      ],
      "fr": [ // translated utterances added to the localization.json by a translator for fr
        "french utterance {slot_name}",
        "another french utterance {slot_name}"
      ]
    }
  },
  "speech": { // map of all in-skill speech to map of Litexa language with any available translations
    "default speech string": { // say/reprompt string found in default Litexa files
      "fr": "override string for FR"
    },
    "say statement|alternate one": { // say/reprompt with their `or` alternates are delineated by `|` characters
      "fr": "french alternate one|french alternate two|french alternate three"
    }
  }
}
```

To add your localized strings, map them from the target language to the string,
for each default string you wish to localize. Litexa's SSML shorthand and
interpolation rules continue to apply.

:::tip Escaped SSML tags require an extra `\`
Due to how say strings are parsed, if you have escaped SSML tags:

```coffeescript
  say "\<amazon:emotion name='excited'>Cats are cute!\</amazon:emotion>"
```

They render in `localization.json` as:

```json
"<amazon:emotion name='excited'>Cats are cute!</amazon:emotion>"
```

And you need to add the escapes back into the mapped translations with another
backslash:

```json
"speech": {
  "<amazon:emotion name='excited'>Cats are cute!</amazon:emotion>": {
    "fr": "\\<amazon:emotion name='excited'>Cats are cute!\\</amazon:emotion>"
  },
  ...
}
```
:::

There's a few things to note. First, utterances for a language are not mapped
one to one, meaning that an intent in the default language might have 3
utterances, and the one for fr-FR might have 5. You can have any number of
utterances for an intent for any language.

Second, say/reprompt strings and their alternatives are mapped together. They appear
as one entry in the file as pipe (`|`) separated strings. As such, your
localized language can have asymmetrical alternatives. Both default and
localized strings follow the same format.

As an example, the say statement in a Litexa file:

```coffeescript
launch
  say "one thing"
    or "another thing"
```

would look like this in `localization.json`:

```json
"speech": {
  // (...)
  "one thing|another thing": {
    "fr-CA": "une chose", // translation can have fewer alternatives
    "fr-FR": "une chose|autre chose|encore une autre chose" // translation can have more alternatives
  }
  // (...)
}
```

Finally, the speech strings function as overrides in the skill. If there is no
translated string for a given language, it will fall back to the default
string.

### Modifying strings in between localization iterations

In the process of skill development, you might revise your default skill code
strings at the same time you are adding localizations to your skill. To help
you keep track of changes, the `localize` command will output a summary of the
`localization.json` strings that have changed.

It's important to remember that the `localize` command reads strings from
*only* the default skill code. To keep things straight, you can keep in mind
these two truths as you localize:

* the default skill code is the source of truth for what utterances and
  say/reprompt strings to localize
* `localization.json` is the source of truth for what's covered for localized
  languages

Here's an example on what would happen if you had modified a string after it
was localized. Your Litexa project initially looks like this, after running
`litexa localize` and adding translations for Spanish:

```coffeescript
# main.litexa
launch
  say "Hello."
    or "Hi."
  say "What's your name?"
```

```json
// localization.json
"speech": {
  "Hello.|Hi.": {
    "es": "Hola."
  },
  "What's your name?": {
    "es": "¿Cómo se llama?"
  }
}
```

If we then changed `main.litexa` to this:

```coffeescript
# main.litexa
launch
  say "Howdy."
  say "What's your name?"
```

Running `litexa localize` would then output this in the console:

```
[localization] +441ms parsing default skill intents, utterances, and output speech ...
[localization] +320ms the following speech lines are new since the last localization:
[localization] +1ms + Howdy.
[localization] +0ms the following speech lines in localization.json are missing in skill:
[localization] +0ms - Hello.|Hi.
```

And `localization.json` would now have:

```json
"speech": {
  "Howdy.": {}, // new line
  "What's your name?": {
    "es": "¿Cómo se llama?"
  },
  "Hello.|Hi.": { // orphaned line
    "es": "Hola."
  }
}
```

So, if the translations from the original string still apply, they should be
copied to the new string mapping manually.

Intents and utterances changed in the same way follow the same behavior.

### `litexa localize` arguments

`litexa localize` can receive some arguments to modify its behavior. To see the
complete list, run `litexa localize --help`.

#### Verbose logs

The `--verbose` flags turns on logging to give more detail on the contents that
have changed from the existing `localization.json`.

#### Auto-removing orphaned strings

Orphaned speech strings and orphaned utterances can be automatically removed
with the `--remove-orphaned-speech` and `--remove-orphaned-utterances` flags,
respectively, but note that doing so will also remove their translations from
`localization.json`.

#### Cloning translations

You can clone existing strings of a language to another language:

```bash
litexa localize --clone-from fr-FR --clone-to fr-CA
```

Cloning existing translations for one language (e.g. fr-FR) to another language
(e.g. fr-CA) can be useful as a starting point for regionalizing a translation
with the same base language.

:::warning Cloning to an existing language
If you clone to a language that already exists, you will overwrite its existing
localization in the localization file.
:::

## Combining both localization strategies

You can combine both localization methods in accordance with your use case
(e.g, project structure-based overrides for assets, and string replacement map
for dialogue). However, they function completely independently of each other.
Also, remember: the string replacement map method only extracts information from the
default language.

## Localization in code

Both localization methods do not cover all cases of localizing strings.
this means that [slotbuilder functions](/book/state-management.html#slots),
`context.say.push` calls, function calls that may use strings, and inline code
speech injection are not localized.

In your Litexa files, you can pass `context.language` to code to retrieve the
Litexa language.

As an example, let's assume your Litexa code had a custom color slot type and
an inline function that injects speech directly into `context.say`:

```coffeescript
# main.litexa
launch
  when "$color"
    with $color = mySlotBuilders.js:myColorSlotBuilder
    injectSpeech(context)
```

The inline code could use `context.language` to do any necessary localization.

```javascript
// inlineCode.js
function injectSpeech(context) {
  switch (context.language) {
    case 'fr':
      context.say.push('Bien!');
      break;
    default:
      context.say.push('Great!');
      break;
  }
}
```

Likewise, slot builders will be provided the same value as a `language`
argument which can be used to do any necessary localization:

```javascript
// mySlotBuilders.js
function myColorSlotBuilder(skill, language){
  const slot = { name: 'myColorSlotName' }
  switch (language) {
    case 'fr':
      slot.values = [ 'bleu', 'rouge' ];
      break;
    default:
      slot.values = [ 'blue', 'red' ];
      break;
  }
  return slot;
}
```

## Testing

To test your skill in a different locale, add the `-r` or `--region` flag to the `litexa test` command.
By default, a vanilla `litexa test` will run your skill in the en-US locale.

Alternatively, you can use the [`setRegion` statement](/reference/#setregion) in
your Litexa test cases. This will override the containing test's locale to the
one in the statement's from that point in the test. However, the simulation's
locale does not change, and as such, the model generated in the `.test`
directory is of the simulation's locale. This statement is useful for iterative
testing of localization, or for regression tests meant specifically for one
locale.

:::warning
Only tests written in the default `litexa` directory will be run. Do not write
test cases within the `languages` directory or any of its subdirectories.
:::

### Inspecting the skill model

To inspect your skill model for a specific locale, execute
`litexa model -r <locale>`. This will print out the skill model for that locale.
You can also look at the `.deploy` directory contents for each skill model
produced for your skill on deployment.

If you've used [DEPLOY variables](/book/expressions.html#deploy-variables) to
change your model for specific deployment targets, you may specify which target
to run the command for by adding the `-d <deployment>` flag.
