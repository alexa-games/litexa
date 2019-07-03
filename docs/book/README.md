# ***Welcome!***

## Foreword

Litexa is an Alexa Skill domain specific language,
runtime and toolchain.

It primarily aims for brevity in describing the
back and forth conversational style of interaction that
defines voice skills. This is done through custom
syntax and flow control that is aligned to Alexa Skill
concepts like intents, utterances, and slots, paired
with a runtime that standardizes useful boilerplate like
state management. A Litexa code file should contain
only the inputs and outputs that make your skill unique.

Litexa was born in sunny California to the Alexa
Games team. This team is tasked with creating games
on Alexa, and then sharing their learnings and technology
with the wider developer community. We developed Litexa
over the course of 2018 while publishing over 20 games,
and continue to use it today. We hope you come to find
it as nurturing an environment as we do!

## On White Space and Comments

Litexa is a "white space dependent" language, like python
or CoffeeScript, as opposed to a bracketed one like C++
or JavaScript. If you're unfamiliar with this concept
here's a quick primer.

The white space, the spaces and or tabs, to the left of
each line of code matters, and is used to group chunks of
related code together.

```
This is statement 1
  This statement is subordinate to statement 1
  This statement is the same, let's call it X
    This statement is subordinate to X
  This statement is back to belonging to statement 1
This statement is subordinate to no one
```

Note how the left edges of statements that belong together
line up. You may choose to use spaces or tabs as your
white space character, but whichever you choose you must
stay consistent: each subsequent line that is intended
to belong together must begin with the exact same white
space characters.

Most modern text editors intended for code will help you
maintain that left edge automatically.

You can leave notes to yourself, comments, by using the
`#` symbol. Any text in a line of code after that symbol
is ignored by the language.

```coffeescript
# anything past that symbol is just ignored

say "Hello There" # even when it's on a line with code
```

## On Editor Support

The team uses Visual Studio Code and JetBrains for development. If you're a Visual Studio Code user, we're more than
happy to share the same VS Code extension we use [here](https://github.com/alexa-games/litexa/tree/master/packages/litexa-vscode/litexa).
This extension adds syntax highlighting for `.litexa` code files. 

For other editors, we recommend extending your `coffeescript` syntax highlighting to include `*.litexa` files. 
However, any modern editor that can handle auto-indenting consecutive lines of code should work just fine.

*Psst, we're a 2 spaces tribe, but we won't hold your white
space preferences against you.*

For more information go to [Editor Support](../book/appendix-editor-support.md).

## Why Litexa?

Litexa is a portmanteau of "Literate" as in [literate
programming](https://en.wikipedia.org/wiki/Literate_programming)
and "Alexa". We chose it to remind ourselves
that our north star is a programming language that favors the
programmer's comfort over the code's.

Also, we just think it's fun to say.
