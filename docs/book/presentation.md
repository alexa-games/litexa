# Audio Presentation

## `Say` Statements

The `say` statement specifies speech content for Alexa
to deliver. It takes one string as an argument and
like any Litexa string accommodates the use of
line breaks to help legibly format your code.

```coffeescript
launch
  say "Hello World.
    Nice to meet you."
```

Subsequent `say` statements encountered during the same
response are accumulated, then concatenated one after
the other with a single space in between.
It is important to keep track of your punctuation to
avoid accidentally creating run-on sentences.

```coffeescript
launch
  say "Hello World."
  -> askAboutRule

askAboutRule
  say "Would you like to play with advanced rules?"
```

The above skill when launch would produce the speech,
*"Hello World. Would you like to play with advanced rules?"*

For heavily trafficked areas of your skill, you may
want to add variations to Alexa's speech. This helps
keep your skill from feeling robotic, and prevents
your users from glossing over important information
hidden in the repetition.

The `or` statement can add variations to `say` statements.
An automated persistent variable will keep track of the
randomization between or statements and guarantee
that on subsequent runs for the same user, they will
not hear the same variation back to back.

```coffeescript
launch
  say "Hello."
    or "Hi there."
    or "Greetings."

  say "Welcome to the Guessing Game."
    or "Let's play the Guessing Game."
```

:::tip
You can combine the `or` statement's variation with the
`say` statement's accumulation as above to produce greater
permuting variation.
To keep localization coherent though, you should try to
keep each fragment of speech as complete as possible!
:::


## Say String Interpolation

As it is very common to inject the values of variables
into Alexa's speech, so Litexa supports that operation
for database and request variables directly in a say
string, relying on the special `@` and `$` prefixes as
control characters.

```coffeescript
  say "Hey there, @userName. How are you?"

  when "I'm feeling $mood"
    with $mood = "happy", "great", "awesome", "fine"
    say "Oh, $mood is a fine mood."
```

In cases where either of those variable types are
objects with function members, those are also invocable
directly.

```coffeescript
  say "Your high score is @leaderboard.myHighScore()."
```

For other interpolation cases, you can inline any valid
expression into a `say` statement by using curly braces.

```coffeescript
  local t = millisecondsSinceStart()
  say "You'be been playing for {t/1000/60} minutes."
```


## SSML Shorthand

Litexa's say strings support some SSML tags via a shorthand
notation. Here's a rundown of the supported shorthands.

`<...1s>` Creates a pause using the "break" SSML tag. The
value can be expressed in milliseconds `<...500ms>` or
`<...1s>` seconds.

`<sfx ding.mp3>` Plays back an audio file at that location,
using the "audio" SSML tag. Relative file references are
assumed to refer to the `litexa/assets` directory.

`<!howdy>` Selects a [speechcon][speechcon]
using the "say-as" SSML tag in "interpret-as" mode. Note
that punctuation should sit inside the speechcon tags in
order to be read correctly, so you'll want to write
`<!howdy.>` rather than `<!howdy>.`

For more information on supported SSML tags, please see the
[Alexa Skill Kit documentation][ssmltags].

[speechcon]: https://developer.amazon.com/docs/custom-skills/speech-synthesis-markup-language-ssml-reference.html#say-as
[ssmltags]: https://developer.amazon.com/docs/custom-skills/speech-synthesis-markup-language-ssml-reference.html

## Escaping Control Characters

The above say string features all rely on treating some
characters as having special meaning, i.e. the `@`, the
`$`, the `{`, the `<` and the bracketing `"`.
You may find yourself needing to use those characters in
your actual text though. When that happens, you'll need
to *escape* their special meaning by prefixing them with
a `\` character.

```coffeescript
  say "That will be \$400 please."
  say "Oh, you mean `"that`" thing."
  say "Her Twitter handle was @martina."
```

Please note that wherever possible, you are better off
spelling out words in an SSML string rather than relying on
symbols that may have ambiguous meanings and be read
incorrectly. So preferably:

```coffeescript
  say "That will be 400 dollars please."
  say "Oh you mean, that, thing?"
  say "Her Twitter handle was, at martina."
```


## `Soundeffect` Statements

Sometimes an audio queue stands alone, maybe it's a piece
of music, or a natural delimiter. In that case, there's is a
dedicated `soundEffect` statement to make your code more
legible.

```coffeescript
launch
  soundEffect intro.mp3
  say "Hi there."
```


## Asset File References

We've seen a few references so far to asset names. More
concretely Litexa assets are files of known type under
the `litexa/assets` directory. For a skill, these will be
referred to at public URLs on the internet, and usually
fetched directly by the user's device, for example audio
files used in SSML, or image files used in APL.

These files are uploaded automatically by the Litexa
deployment mechanism, with each named deployment for a
project creating a new online location and copy of the
assets to remain in sync with the deployment. References
in your code to these files are patched up by the Litexa
runtime to point to their correct final locations.

See the [Deployment](/book/deployment.md) chapter for
more information on how asset files end up in the right place.

Asset files can also be localized, with replacement
files optionally specified for each language you want
to support. See the [Localization](/book/localization.md)
chapter for more information on that topic.

There is also a Litexa extension for converting
WAV audio to Alexa-compatible audio. See the [WAV Audio
Conversion Appendix](/book/appendix-wav-conversion.md) for
more information on when and how to use it.
