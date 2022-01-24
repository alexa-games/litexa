# Litexa APLA

This package is an extension for [Litexa](www.litexa.com) that
adds support for creating [APLA](https://developer.amazon.com/en-US/docs/alexa/alexa-presentation-language/apl-for-audio-reference.html)
responses out of Litexa semantics.

This is largely achieved through a new Litexa concept: an APLA
"block", a named region of material that belongs together.

An APLA Block can have an optional background track, on top of
which it will combine any number of Litexa `say` and `soundEffect`
statements, the way you'd normal expect them to concatenate in
`outputSpeech`. For example, the following Litexa:

```coffeescript
launch
  APLABlock "intro"
    background: intro-jingle.mp3
    fadeIn: 1000
    loop: 3
    delay: 3000

  say "Welcome to the skill!"
  if daysBetween( @lastLaunch, context.now ) > 6
    say "Haven't seen you in a while now, lots to catch up on!"

  @lastLaunch = context.now

  soundEffect ready.mp3

  say "Let's get right to it."
    or "I'm ready to get into it."
  -> getStarted

```

...might produce the an APLA document with the following mainTemplate:

```javascript
mainTemplate: {
  items: [
    {
      id: "intro",
      type: "Sequencer",
      items: [
        {
          type: "Mixer",
          items: [
            {
              items:
              [
                {
                  type: "Audio",
                  source: "intro-jingle.mp3",
                  filter: { type: "fadein" }
                },
                {
                  type: "Audio",
                  source: "intro-jingle.mp3"
                },
                {
                  type: "Audio",
                  source: "intro-jingle.mp3"
                }
              ]
            },
            {
              type: "Sequence",
              items: [
                {
                  type: "Silence",
                  duration: 3000
                },
                {
                  type: "Speech",
                  content: "<speak>Welcome to the skill! Haven't seen you in a while now, lots to catch up on!</speak>"
                },
                {
                  type: "Audio",
                  source: "ready.mp3"
                },
                {
                  type: "Speech",
                  content: "<speak>I'm ready to get into it.</speak>"
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

You can disable APLA generation temporarily for any given response by setting the variable `APLA.disableAPLA` to `true`.