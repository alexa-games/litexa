{
  /*
    Note: the grammar below isn't entirely context free because
    tracking blocks of whitespace is easier this way.
    We keep track of indentation as a "current lead", and
    take some actions when that state changes.

    Everything UNDER the block level though, should legitimately
    NOT rely on global state. Keep it that way.
  */

  var lib = options.lib;
  var skill = options.skill;
  if ( !skill ) {
    skill = new lib.Skill;
  }
  var ParserError = lib.ParserError;
  var lead = "";

  var stack = [
    { lead: "", target:skill }, // skill
    { lead: null, target:null }, // state
    { lead: null, target:null }, // intent / conditional
    { lead: null, target:null }, // ?
    { lead: null, target:null }, // ?
    { lead: null, target:null }, // ?
    { lead: null, target:null } // ?
  ];

  var currentLineOffset = 0;
  var oldLocation = location;
  location = function() {
    var l = oldLocation();
    l.start.line -= currentLineOffset;
    l.end.line -= currentLineOffset;
    l.source = options.source;
    l.language = options.language;
    return l;
  }

  function indent(ws, location) {
    var indentation = ws.length;
  }


  var popStackTo = function(index) {
    for ( var i=index+1; i<stack.length; ++i) {
      stack[i] = { lead:null, target: null };
    }
  }

  var getTarget = function() {
    for ( var i=0; i<stack.length; ++i ) {
      var s = stack[i];
      if (lead === s.lead) {
        return s.target;
      }
    }
    return null;
  }

  var popToTarget = function() {
    var after = false;
    for ( var i=0; i<stack.length; ++i ) {
      var s = stack[i];
      if (after) {
        stack[i] = { lead:null, target: null };
      } else {
        if (lead === s.lead) {
          after = true;
        }
      }
    }
  }

  var pushToStack = function(thing) {
    var after = false;
    for (var i=0; i<stack.length; ++i) {
      if ((stack[i].target === null || stack[i].lead === null) && !after) {
        stack[i] = { lead: null, target: thing };
        after = true;
      } else {
        if (after) {
          stack[i] = { lead: null, target: null };
        }
      }
    }
    if (!after) {
      throw new ParserError(location(), "Failed to push " + thing.constructor.name + " onto stack");
    }
  }

  var pushState = function(stateName) {
    var state = skill.pushOrGetState(stateName, location());
    popStackTo(0);
    pushToStack(state);
  }

  var pushTest = function(testName) {
    var test = new lib.Test(location(), testName, options.source);
    popStackTo(0);
    pushToStack(test);
    skill.pushTest(test);
  }

  var pushDataTable = function(tableName, headerNames) {
    var table = new lib.DataTable(tableName, headerNames);
    popStackTo(0);
    pushToStack(table);
    skill.pushDataTable(table);
  }

  var pushIntent = function(location, utterance, intentInfo, fromAlternate) {
    if (stack[2].lead != null) {
      if (fromAlternate) {
        if (stack[3].lead == null) {
          const parentIntent = getTarget();
          if (parentIntent.hasAlternateUtterance) {
            throw new ParserError(location, `Can't add intent name \`${utterance}\` as an \`or\` alternative to \`${parentIntent.name}\` `
              + `because it already has utterance alternatives. Intent name and utterance alternatives can't be combined in a single handler; `
              + `please use one or the other.`);
          }
          const intent = stack[0].target.pushIntent(stack[1].target, location, utterance, intentInfo);
          return intent;
        }
        throw new ParserError(location, `Invalid indentation of \`or ${utterance}\`: ` +
          `\`or\` statements for \`when\` statements must begin at the second level of indentation.`);
      }
      throw new ParserError(location, `Invalid indentation of \`when ${utterance}\`: ` +
        `\`when\` statements can only be directly subordinate to a state and must begin at the first level of indentation.`);
    }
    const intent = stack[0].target.pushIntent(stack[1].target, location, utterance, intentInfo);
    popStackTo(1);
    pushToStack(intent);
    return intent;
  }

  var pushSay = function(location, say) {
    say.location = location
    const target = getTarget();
    if (target && target.pushCode) {
      target.pushCode(say);
      pushToStack(say);
    } else {
      throw new ParserError(location, "Couldn't find anything to append a 'say' to here");
    }
  }


  var pushBlock = function(type, location, condition) {
    condition.location = location
    const target = getTarget();
    if (target && target.pushCode) {
      target.pushCode(condition);
      popToTarget();
      pushToStack(condition);
    } else {
      throw new ParserError(location, "Couldn't find anything to append `" + type + "` to here");
    }
  }

  var pushIf = function(location, condition) {
    pushBlock('if', location, condition);
  }

  var pushFor = function(location, condition) {
    pushBlock('for', location, condition);
  }

  var pushSwitch = function(location, condition) {
    pushBlock('switch', location, condition);
  }

  var pushSwitchCase = function(location, switchCase) {
    switchCase.location = location
    const target = getTarget();
    if (target && target.pushCase) {
      target.pushCase(switchCase);
      popToTarget();
      pushToStack(switchCase);
    } else {
      throw new ParserError(location, "Couldn't push a case statement here, no switch statement found to add it to.");
    }
  }


  var testLead = function(location, spacing) {
    if (spacing.length > lead.length) {
      var i = 0;
      for (; i<stack.length; ++i) {
        var s = stack[i];
        if ( s.target !== null && s.lead === null ) {
          s.lead = spacing;
          break;
        }
      }
      for (++i; i<stack.length; ++i) {
        stack[i] = { lead:null, target:null };
      }
    }
    else if (spacing.length < lead.length) {
      var i = 0;
      for (; i<stack.length; ++i) {
        var s = stack[i];
        if ( s.lead && (s.lead.length > spacing.length) ) {
          s.lead = null;
          s.target = null;
        }
        else if ( s.lead === null ) {
          s.target = null;
        }
      }
    }
    lead = spacing;
  }

  var typeIs = function(type) {
    return stack[stack.length-1].target.isType(type);
  }

  var pushStatement = function(statement) {
    var b = stack[stack.length-1];
  }


  var pushCode = function(location, thing) {
    const target = getTarget();
    if (target && target.pushCode) {
      thing.location = location;
      target.pushCode(thing);
    } else {
      throw new ParserError(location, "Couldn't find anything to push code into here");
    }
  }

  var currentTest = function() {
    if (stack[1].target && stack[1].target.isTest) {
      return stack[1].target;
    }
    throw new ParserError(location(), "pushing a test statement without a current test");
  }

  var isTopTarget = function(name) {
    return stack[1].target && stack[1].target[name];
  }

  if (options.test) {
    popStackTo(0);
    pushToStack(options.test);
  }
}


start
  = StatementDecorated* {
    return skill;
  }

StatementDecorated
  = __ EndOfStatementSequence
  / RootStatements __ EndOfStatementSequence
  / Lead st:Statement EndOfStatementSequence
  / Lead st:Statement __ EndOfStatementSequence

EndOfStatementSequence
  = LineTerminatorSequence / EndOfFile
  / CommentStatement __ LineTerminatorSequence / EndOfFile

EndOfFile "End of File"
  = '\u001A'


Lead
  = ___ {
    testLead(location(), text());
  }

Statement
  = &{return isTopTarget('isState');} StateStatements
  / &{return isTopTarget('isTest');} TestStatements
  / &{return isTopTarget('isDataTable');} TableStatements
  / CommentStatement

RootStatements
  = DefineStatement
  / ExcludeStatement
  / PronounceStatement
  / NewTestStatement
  / NewDataTableStatement
  / NewStateStatement
  / CommentStatement

StateStatements
  = ConditionalStatement
  / ForStatement
  /* ADDITIONAL STATEMENTS */
  / LogStatement
  / SwitchCaseStatement
  / FunctionCallStatement
  / OtherwiseStatement
  / EndStatement
  / ListenStatement
  / StopAndGotoStatement
  / GotoStatement
  / MetricStatement
  / SwitchStatement
  / ResponseSpacingStatement
  / SettingStatement
  / DatabaseAssignmentStatement
  / SoundEffectStatement
  / PlayMusicStatement
  / StopMusicStatement
  / SayStatement
  / RepromptStatement
  / SayRepromptStatement
  / CardStatement
  / DirectiveStatement
  / HandoffStatement
  /* ADDITIONAL INTENT STATEMENTS */
  / IntentStatement
  / AlternativeStatement
  / SlotTypeStatement
  / AttributeStatement
  / CommentStatement
  / LocalVariableStatement
  / LocalVariableAssignmentStatement
  / SlotVariableAssignmentStatement
  /* MONETIZATION */
  / BuyInSkillProductStatement
  / CancelInSkillProductStatement
  / UpsellInSkillProductStatement


TestStatements
  = TestLaunchStatement
  /* ADDITIONAL TEST STATEMENTS */
  / TestWaitStatement
  / TestQuitStatement
  / TestListenStatement
  / TestDirectiveStatement
  / TestLineAlexa
  / TestLineUser
  / TestLineAlternate
  / TestEndStatement
  / TestLineExpectedDB
  / TestSetRegion
  / TestCapture
  / TestResume
  / TestLogStateTraces
  / TestLineRequest


TableStatements
  = DataTableRowStatement




// Fragment is used as an entry point
// in the test framework to parse chunks
Fragment
  = Fragments ___

Fragments
  = CardStatement
  / SayStatement


/* litexa [State]
A state is defined by writing an [Identifier](#identifier) as the
first and only thing on its own line.

See the State Management chapter of the Book, for more information.
*/

NewStateStatement
  = StateName {
    testLead(location(), "");
    pushState(text());
  }

/* litexa [define]
Coming soon!
*/
DefineStatement "database type definition"
  = "define" ___ '@' name:Identifier ___ 'as'___ type:DottedIdentifier {
    skill.pushDBTypeDefinition( new lib.DBTypeDefinition(location(), name, type) );
  }


AllFileExclusions
  = results:AllFileExclusionsStatment* {
    if ( !results ) {
      return true;
    }
    let shouldInclude = true;
    for ( let i=0; i<results.length; ++i ) {
      if ( !results[i] ) {
        shouldInclude = false;
      }
    }
    return shouldInclude;
  }

AllFileExclusionsStatment
  = __ EndOfStatementSequence { return true; }
  / r:ExcludeStatement __ EndOfStatementSequence { return r; }
  / $(!EndOfStatementSequence .)* EndOfStatementSequence { return true; }

/* litexa [exclude file]
The `exclude file` statement lets you specify a static [expression](
#expression) to exclude all the contents of the file. You might want to exclude
a file of test states from a production build, or exclude a file from versions
of your skill, as defined by your [DEPLOY](#deploy-variable) variables.

The statement can also be used to skip a `.test.litexa` file if the tests within
aren't relevant and would otherwise fail for the deployment target being tested.
For instance:

```coffeescript
# campaign.test.litexa
exclude file unless DEPLOY.ENABLE_CAMPAIGN

TEST "campaign setup"
  # ...

# other tests for campaign mode that assume DEPLOY.ENABLE_CAMPAIGN == true
```

:::warning
This statement only works on files that exclusively have tests or states
that don't have any transitions to them.
:::
*/
ExcludeStatement "file exclusion statement"
  = "exclude file" ___ type:("if"/"unless") ___ expr:ExpressionString {
    if (options.context) {
      let result = expr.evaluateStatic(options.context);
      if (type === "unless") {
        return result == true;
      } else {
        return result == false;
      }

    }
    return null;
  }


/* litexa [if]
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
*/

/* litexa [unless]
The negated version of the [if](#if) statement. Note: unless
statements do not support a dependent else statement.
*/


ConditionalStatement "conditional statement"
  = "if" ___ expression:ExpressionString {
      pushIf(location(), new lib.IfCondition(expression));
    }
  / "unless" ___ expression:ExpressionString {
      pushIf(location(), new lib.IfCondition(expression, true));
    }
  / "else" ___ "if" ___ expression:ExpressionString {
      pushIf(location(), new lib.ElseCondition(expression));
    }
  / "else" ___ "unless" ___ expression:ExpressionString {
      pushIf(location(), new lib.ElseCondition(expression, true));
    }
  / "else" {
      const target = getTarget();
      if (target && target.pushCode) {
        pushIf(location(), new lib.ElseCondition());
      } else if (target && target.pushCase) {
        pushSwitchCase(location(), new lib.SwitchCase(location(), "else"));
      } else {
        throw new ParserError(location(), "there isn't anything to `else` here");
      }
    }

/* litexa [for]
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

*/
ForStatement "for statement"
  = "for" ___ key:Identifier __ "," __ value:Identifier ___ "in" ___ source:ExpressionString {
    pushFor(location(), new lib.ForStatement(key, value, source));
  }
  / "for" ___ value:Identifier ___ "in" ___ source:ExpressionString {
    pushFor(location(), new lib.ForStatement(null, value, source));
  }


/* litexa [switch]

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

*/

/* litexa [then]
Terminates case statements for the [switch](#switch) statement.
*/

SwitchStatement
  = "switch" ___ assigns:SwitchAssignments {
    pushSwitch(location(),  new lib.SwitchStatement(assigns));
  }
  / "switch" {
    pushSwitch(location(),  new lib.SwitchStatement([]));
  }

SwitchAssignments
  = head:SwitchAssignment __ tail:(SwitchAssignmentsTail)*  {
    tail = tail || [];
    tail.unshift(head);
    return tail;
  }

SwitchAssignmentsTail
  = "," __ assign:SwitchAssignment { return assign; }

SwitchAssignment
  = name:Identifier __ "=" __ value:ExpressionString {
      return new lib.SwitchAssignment(location(), name, value);
    }
  / value:ExpressionString {
      return new lib.SwitchAssignment(location(), null, value);
    }
  / name:VariableReference {
      return new lib.SwitchAssignment(location(), name, null);
    }
  / '@' name:VariableReference {
      name = new lib.DatabaseReferencePart(name);
      return new lib.SwitchAssignment(location(), name, null);
    }
  / 'DEPLOY.' name:VariableReference {
      name = new lib.StaticVariableReferencePart(name);
      return new lib.SwitchAssignment(location(), name, null);
    }
  / name:SlotVariableReference {
      name = new lib.SlotReferencePart(name);
      return new lib.SwitchAssignment(location(), name, null);
    }


SwitchCaseStatement
  = SwitchCaseRegex
  / SwitchCaseComparison
  / SwitchCaseExpression


/* litexa [Switch Regular Expression Case]
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
*/

SwitchCaseRegex
  = "match" ___ regex:RegexLiteral ___ "then" {
    pushSwitchCase(location(), new lib.SwitchCase(location(), 'regex', regex));
  }

/* litexa [Switch Comparison Case]
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
*/

SwitchCaseComparison
  = op:SwitchCompareOperator __ expr:ExpressionString ___ "then" {
    pushSwitchCase(location(), new lib.SwitchCase(location(), op, expr));
  }


/* litexa [Switch Expression Case]
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

*/

SwitchCaseExpression
  = expr:ExpressionString ___ "then" {
      pushSwitchCase(location(), new lib.SwitchCase(location(), 'expr', expr));
    }

/* litexa [Switch Comparison Operators]
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
*/

SwitchCompareOperator "Switch Comparison Operator"
  = '=='
  / '!='
  / '<='
  / '>='
  / '<'
  / '>'


/* litexa [Regular Expression]
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

*/

RegexLiteral
  = '/' (RegexLiteralCharacter+'/'[gi]*) {
    const splitIndex = text().lastIndexOf('/');
    return { expression: text().substring(1,splitIndex), flags: text().substring(splitIndex+1) };
  }

RegexLiteralCharacter
  = [a-zA-Z0-9|*+()=\-_\'<>!:?.,^${}\[\] ]
  / ('\\' [wWdDsSbBtnr.+*?$^\\\/\[\](){}=!<>|:-])

/* litexa [say]
Adds spoken content to the next response. The content
is specified in the [Say String](#say-string) format.

Say statements are accumulative until the next
response is sent, with each subsequent statement
being separated by a single space.

```coffeescript
say "Hello"
say "World"
# would result in Alexa saying "Hello World"
```
*/

SayStatement
  = "say" ___ say:SayString {
    pushSay(location(), say);
  }

/* litexa [reprompt]
Adds a [Say String](#say-string) to the pending skill response's reprompt speech.
Same as the [say](#say) statement, any reprompted fragments are accumulated.
```coffeescript
reprompt "Hello"
reprompt "World"
# would result in Alexa reprompting "Hello World"
```
*/

RepromptStatement
  = "reprompt" ___ say:SayString {
    say.isReprompt = true;
    pushSay(location(), say);
  }

/* litexa [say reprompt]
Combines the [say](#say) and [reprompt](#reprompt) functionality: The indicated
[Say String](#say-string) is added to both the pending skill response's output speech
and reprompt speech.

```coffeescript
say reprompt "something"
# equivalent to:
# say "something"
# reprompt "something"
```
*/

SayRepromptStatement
  = "say reprompt" ___ say:SayString {
    say.isAlsoReprompt = true
    pushSay(location(), say);
  }

/* litexa [soundEffect]
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
*/

SoundEffectStatement
  = "soundEffect" ___ asset:AssetName {
    pushSay(location(), new lib.SoundEffect(location, asset));
  }
  / "soundEffect" ___ asset:AssetURL {
    pushSay(location(), new lib.SoundEffect(location, asset));
  }
  / "soundEffect" ___ asset:AssetSoundBank {
    pushSay(location(), new lib.SoundEffect(location, asset));
  }



/* litexa [playMusic]
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
*/
PlayMusicStatement
  = "playMusic" ___ asset:AssetName {
    pushCode(location(), new lib.PlayMusic(location, asset));
  }
  / "playMusic" ___ asset:AssetURL {
    pushSay(location(), new lib.PlayMusic(location, asset));
  }

/* litexa [stopMusic]
Issues an [AudioPlayer Stop](https://developer.amazon.com/docs/custom-skills/audioplayer-interface-reference.html#stop)
directive. The directive halts any ongoing AudioPlayer stream (e.g. such as one started with the
[playMusic](#playmusic) statement).

```coffeescript
stopMusic
```
*/
StopMusicStatement
  = "stopMusic" {
    pushCode(location(), new lib.StopMusic(location));
  }


/* litexa [pronounce]
Specifies a one for one replacement that will be automatically
applied to all voiced responses from this skill. The statement
should be placed outside of the scope of any state, at the top
level of the file.

Use this to improve Alexa's pronunciation of words, or select
a specific pronunciation skill-wide, while retaining human
readable spelling in your code.

```coffeescript
pronounce "tomato" as "<phoneme alphabet="ipa" ph="/təˈmɑːtoʊ/">tomato</phoneme>"
```

Note that you must use SSML in the replacement text; the Litexa
SSML shorthand statements (e.g "<!Bravo>") will not work.

### Localized Pronunciations

If you plan to publish your skill to multiple locales, you can define
locale-specific pronunciations for your voiced responses. Simply add
your locale-specific pronunciation definitions to the Litexa files that
reside in said locale's Litexa project directory (see the Localization
chapter for further information).

:::tip Tip
We recommend using a standalone file (e.g. `pronounce.litexa`) for
pronunciation definitions.
:::

:::warning Note
Opposite to Litexa's structured-based override features of localization,
the default locale's pronunciations will not carry over to other locales.
:::
*/

PronounceStatement
  = "pronounce" ___ source:QuotedString ___ "as" ___ target:QuotedString {
    skill.pushSayMapping(location(), source, target);
  }

/* litexa [card]
Sends a card to the user's companion app with a title, an image, and/or text.

See the The Companion App chapter of the Book for more details.

```coffeescript
card "Welcome", image.png, "This is my wonderful card"
...
card "Another Way"
  image: image.png
  content: "Another way to initialize a card"
```
*/
CardStatement
  = "card" ___ title:ScreenString __ "," __ image:CardImageReference __ "," __ content:ScreenString {
      pushSay(location(), new lib.Card(location(), title, content, image));
    }
  / "card" ___ title:ScreenString __ "," __ image:CardImageReference {
      pushSay(location(), new lib.Card(location(), title, null, image));
    }
  / "card" ___ title:ScreenString __ "," __ content:ScreenString {
      pushSay(location(), new lib.Card(location(), title, content, null));
    }
  / "card" ___ title:ScreenString {
      pushSay(location(), new lib.Card(location(), title, null, null));
    }
  / "card" ___ image:CardImageReference {
      pushSay(location(), new lib.Card(location(), null, null, image));
    }

CardImageReference
  = AssetURL / AssetName / VariableReference

ScreenImageReference
  = AssetURL / AssetName / VariableReference


/* litexa [directive]
Adds directives to the next Alexa response, by calling an
[Inline Function](#inline-function). The function is expected to return
an array of JavaScript objects each representing a
single directive.

```coffeescript
directive createIntroAPLScreen()
```

For more on Alexa directives, see:
[Alexa Interfaces, Directives and Events](https://developer.amazon.com/docs/alexa-voice-service/interaction-model.html#interfaces)
*/
DirectiveStatement
  = "directive" __ expression:ExpressionString {
    pushCode(location(), new lib.Directive(expression));
  }


/* litexa [metric]
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
*/
MetricStatement
  = "metric" ___ name:MetricName {
    pushCode(location(), new lib.RecordMetric(name));
  }

MetricName
  = ([a-z] / [A-Z] / [0-9] / '-' )+ {
    return text();
  }

/* litexa [setResponseSpacing]
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
*/
ResponseSpacingStatement
  = "setResponseSpacing" __ "=" __ amount:Integer {
    pushCode(location(), new lib.SetResponseSpacing(amount));
  }


AttributeStatement
  = key:"message" __ ":" __ value:QuotedString {
    // @TODO: This is an edge case for the upsellInSkillProduct statement, so that the <upsell> tag
    // won't be treated as a "ScreenString" tag. Ultimately, we should handle this more cleanly.
    const target = getTarget();
    if (target && target.pushAttribute) {
      target.pushAttribute(location(), key, value);
    } else {
      throw new ParserError(location(), "Couldn't find anything to add an attribute to here");
    }
  }
  / key:ExistingIdentifier __ ":" __ value:(Number / AssetURL / JsonFileName / AssetName / BooleanLiteral / VariableReference / ScreenString / QuotedString / ExpressionString) {
    const target = getTarget();
    if (target && target.pushAttribute) {
      target.pushAttribute(location(), key, value);
    } else {
      throw new ParserError(location(), "Couldn't find anything to add an attribute to here");
    }
  }


/* litexa [when]
Declares an intent that the parent state is willing to handle.

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
by a series of one of the two following subordinate statements.

1. The statement can be followed by [or](#or) utterance statements that offer
alternative ways to specify the same intent.

```coffeescript
when "my name is $name"
  or "I'm $name"
  or "call me $name"
```

2. The statement can be followed by [or](#or) intent name statements to have
these intents share the same handler.

```coffeescript
when RephraseQuestionIntent
  or AMAZON.RepeatIntent
  or UnsureIntent
```

These types of subordinate statements cannot be mixed; doing so will result in a
compile time error.

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

### Postfix Conditional

The statement can include a conditional static [expression](
#expression). If the condition evaluates to false, then the handler will not
exist in that state.

```coffeescript
forkInTheRoad
  say "Do you want to go left or right?"

  when AlwaysCorrectPath if DEPLOY.shortcutsEnabled
    or "the correct path"
    or "next"
    ...

  when SkipToEnding if DEPLOY.shortcutsEnabled
    -> ending

  ... # other handlers

  otherwise
    say "I didn't get that."
    -> forkInTheRoad

```

This can be a way to exclude some intents for specific deployment targets. For
the above example, if this was the only place `AlwaysCorrectPath` was defined,
it would not exist in the language model for the deployment targets that have
`DEPLOY.shortcutsEnabled = true`. On the other hand, `SkipToEnding` is defined
elsewhere because there are no utterances attached to its statement, so it will
exist in the language model.

If the skill is deployed with a deployment target that does not have `DEPLOY.
shortcutsEnabled = true` and the skill receives `SkipToEnding` in this state,
Litexa will have the [`otherwise`](#otherwise) handler resolve it.

It may be useful to learn about [DEPLOY variables](#deploy-variable) and static
[expressions](#expression) for these statements.

*/

/* litexa [Intent Name]
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
*/

/*  litexa [Utterance]
An example phrase to be spoken by the user that maps to an intent.
Utterances in Litexa are defined in [when](#when) statements.

Please read the State Management chapter for more information on intents and utterances.
*/
IntentStatement
  = "when" ___ ![a-zA-Z"] {
    throw new ParserError(location(), "intent identifiers must begin with a letter, upper or lower case");
  }
  / "when" ___ "Connections.Response" ___ name:QuotedString {
    const intent = pushIntent(location(), 'Connections.Response', {class:lib.FilteredIntent});

    intent.setCurrentIntentFilter({
      name,
      data: { name }, // Persist "name" for the filter to have access to it at runtime.
      filter: function(request, data) {
        return (request.name === data.name);
      },
      callback: async function() {
        // If this Connections.Response is filtered by monetization events, let's add two
        // shorthand accessors for $purchaseResult and $newProduct.
        const monetizationResponses = [ 'Buy', 'Cancel', 'Upsell' ];
        if (monetizationResponses.includes(context.event.request.name)) {
          const __payload = context.event.request.payload;

          if (__payload && __payload.purchaseResult && __payload.productId) {
            context.slots.purchaseResult = __payload.purchaseResult;
            context.slots.newProduct = await getProductByProductId(context, __payload.productId);
          }
        }
      }
    });
  }
  / "when" ___ "Connections.Response" {
    const intent = pushIntent(location(), 'Connections.Response', {class:lib.FilteredIntent});
    intent.setCurrentIntentFilter({ name: '__' });
  }
  / "when" ___ utterance:(UtteranceString / DottedIdentifier) ___ type:("if"/"unless") ___ qualifier:ExpressionString {
    const intent = pushIntent(location(), utterance, false);
    intent.qualifier = qualifier;
    if (type === "unless") {
      intent.qualifierIsInverted = true;
    }
  }
  / "when" ___ utterance:(UtteranceString / DottedIdentifier) {
    const intent = pushIntent(location(), utterance, false);
  }

/* litexa [or]
Used to provide variations to various statements:
* [say](#say)
* [when](#when)
* [soundEffect](#soundeffect)
*/

AlternativeStatement
  = "or" ___ utterance:(DottedIdentifier) ___ type:("if"/"unless") ___ qualifier:ExpressionString {
    const intent = pushIntent(location(), utterance, false, true);
    intent.qualifier = qualifier;
    if (type === "unless") {
      intent.qualifierIsInverted = true;
    }
  }
  / "or" ___ parts:(SayStringParts) {
    const target = getTarget();
    if (target && target.pushAlternate) {
      if (target instanceof lib.Intent) {
        if (target.hasChildIntents()) {
          throw new ParserError(location, `Can't add utterance as an \`or\` alternative to \`${target.name}\` because it `
            + `already has intent name alternatives. Utterance and intent name alternatives can't be combined in a single handler; `
            + `please use one or the other.`);
        }
      }
      target.pushAlternate(parts, skill);
    } else {
      throw new ParserError(location(), "Couldn't find anything to add an alternative to here");
    }
  }
  / "or" ___ parts:(AssetName / DottedIdentifier) {
    const target = getTarget();
    if (target instanceof lib.Intent) {
      if (parts.isAssetName) { // parts was parsed into an AssetName type; reconstruct it as the original text
        parts = parts.toString();
      }
      const intent = pushIntent(location(), parts, false, true);
      target.pushChildIntent(intent);
    } else if (target && target.pushAlternate) {
      target.pushAlternate(parts, skill);
    } else {
      throw new ParserError(location(), "Couldn't find anything to add an alternative to here");
    }
  }

/* litexa [with]
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
    values: [
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
*/

SlotTypeStatement
  = "with" ___ name:SlotVariableReference __ "=" __ type:(FileFunctionReference/DottedIdentifier/StringLiteralList) {
    const target = getTarget();
    if (target && target.pushSlotType) {
      target.pushSlotType(location(), name, type);
    } else {
      throw new ParserError(location(), "Cannot define a slot type here");
    }
  }

/* litexa [otherwise]
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

*/
OtherwiseStatement
  = "otherwise" {
    const target = getTarget();
    if (target && target.pushOrGetIntent) {
      pushIntent(location(), '--default--', false);
    } else {
      throw new ParserError(location(), "there isn't anything to `otherwise` here");
    }
  }

/* litexa [@ variable]
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
*/
DatabaseAssignmentStatement
  = '@' name:VariableReference __ "=" __ expression:ExpressionString {
    pushCode(location(), new lib.DBAssignment(name, expression));
  }

/* litexa [local]
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
*/
LocalVariableStatement
  = "local" ___ name:Identifier __ "=" __ '@' source:DottedIdentifier ___ "as" ___ className:Identifier {
      pushCode(location(), new lib.WrapClass(className, name, source));
    }
  / "local" ___ name:Identifier __ "=" __ expression:ExpressionString {
      pushCode(location(), new lib.LocalDeclaration(name, expression));
    }
  / "local" ___ name:Identifier {
    throw new ParserError(location(), "You cannot create local variable without giving it a value. Please add one!");
  }

LocalVariableAssignmentStatement
  = name:ExistingIdentifier __ "=" __ expression:ExpressionString {
    pushCode(location(), new lib.LocalVariableAssignment(name, expression));
  }

/* litexa [$ variable]
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
### Slot Variables

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

### General-Purpose Variables

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

*/
SlotVariableAssignmentStatement
  = '$' name:VariableReference __ "=" __ expression:ExpressionString {
    pushCode(location(), new lib.SlotVariableAssignment(location(), name, expression));
  }

/* litexa [buyInSkillProduct]
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
*/
BuyInSkillProductStatement
  = "buyInSkillProduct" __ referenceName:QuotedString {
    pushCode(location(), new lib.BuyInSkillProductStatement(referenceName));
  }

/* litexa [cancelInSkillProduct]
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
*/
CancelInSkillProductStatement
  = "cancelInSkillProduct" __ referenceName:QuotedString {
    pushCode(location(), new lib.CancelInSkillProductStatement(referenceName));
  }

/* litexa [upsellInSkillProduct]
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
*/
UpsellInSkillProductStatement
  = "upsellInSkillProduct" __ referenceName:QuotedString {
    // @TODO: pushSay is currently required for attributes: Why?!
    pushSay(location(), new lib.UpsellInSkillProductStatement(referenceName));
  }


/* litexa [Comments]
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
*/

CommentStatement
  = "#" $(!EndOfStatementSequence .)*


/* litexa [log]
Writes the result of the given [Expression](#expression) to your logging system.

In the standard `@litexa/deploy-aws` library, this will write
to your Lambda's Cloudwatch log.
*/
LogStatement
  = "log" ___ expression:ExpressionString {
    pushCode(location(), new lib.LogMessage(expression));
  }


/* litexa [END]
Indicates that your skill should end after the next response, so
it should not expect any further interaction from the user.
*/
EndStatement
  = "END" {
    pushCode( location(), new lib.SetSkillEnd() );
  }

/* litexa [LISTEN]
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
*/
ListenStatement
  = "LISTEN" ___ head:ListenKind __ tail:ListenStatementTail* {
    tail = tail || [];
    tail.unshift(head);
    pushCode( location(), new lib.SetSkillListen(tail) );
  }
  / "LISTEN" {
    pushCode( location(), new lib.SetSkillListen([]) );
  }

ListenStatementTail
  = ',' __ kind:ListenKind { return kind; }

ListenKind
  = 'events' / 'microphone'


/* litexa [->]
Queues the next state to be executed after the current one
completes. The given name should refer to a state anywhere
else in the current project.

Note, this does *not* transition to the next
state immediately, the current state will always complete
first.

```coffeescript
  -> askUserForName
```
*/
GotoStatement
  = "->" __ name:Identifier {
    pushCode(location(), new lib.Transition(name, false));
  }

StopAndGotoStatement
  = "|->" __ name:Identifier {
    pushCode(location(), new lib.Transition(name, true));
  }

HandoffStatement
  = "..." __ name:Identifier {
    pushCode(location(), new lib.HandoffIntent(name));
  }

/* litexa [set]
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
*/
SettingStatement
  = "set" ___ variable:Identifier __ "=" __ condition:("true"/"false") {
    pushCode(location(), new lib.SetSetting(variable, condition));
  }

/* litexa [TEST]
Names a Litexa test case. All statements in the test will
then be indented.

```coffeescript
TEST "first time user interaction"
  launch
  ... # rest of the test case
```
*/
NewTestStatement
  = "TEST" ___ name:QuotedString {
    testLead(location(), "");
    pushTest(name);
  }

/* litexa [wait]
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

*/
TestWaitStatement
  = "wait" ___ size:Integer ___ unit:TimeUnit {
    if ( unit == "day" ) { size *= 24 * 60 * 60 * 1000; }
    else if ( unit == "hour" ) { size *= 60 * 60 * 1000; }
    else if ( unit == "second" ) { size *= 1000; }
    else { size *= 60 * 1000; } // minutes by default
    currentTest().pushWait( size );
  }

TimeUnit
  = unit:("second"/"minute"/"hour"/"day") "s" {
      return unit
    }
  / unit:"second"/"minute"/"hour"/"day" {
      return unit
    }

/* litexa [launch]
Simulates the user invoking the skill in a Litexa test.
Starts the skill session in the `launch` state.

**Warning:** Litexa does not prevent you from using `launch` in the
middle of your test, such as after another intent. It will
take you to the `launch` state. However, on a real Alexa
device, this is equivalent to saying "Alexa, launch \<my
skill\>" in the middle of your skill session. Unless utterances for
launching skills are part of your skill model, your skill will most
likely receive some other intent instead.
*/
TestLaunchStatement
  = "launch" {
    currentTest().pushUser(location());
  }

/* litexa [quit]
Coming soon!
*/
TestQuitStatement
  = "quit" {
    currentTest().pushStop('quit');
  }

/* litexa [LISTEN (Testing)]
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

*/
TestListenStatement
  = "LISTEN" ___  head:ListenKind __ tail:ListenStatementTail* {
    tail = tail || [];
    tail.unshift(head);
    currentTest().pushExpectation(new lib.ExpectedContinueSession(location(), tail));
  }
  / "LISTEN" {
    currentTest().pushExpectation(new lib.ExpectedContinueSession(location(), []));
  }

/* litexa [END (Testing)]
Asserts that your skill response indicated that the skill
session should end.

For an example, see [LISTEN (Testing)](#listen-testing).
*/
TestEndStatement
  = "END" {
    currentTest().pushExpectation(new lib.ExpectedEndSession(location()));
  }

/* litexa [user:]
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

*/
TestLineUser
  = "user:" __ line:SayString __ "with" ___ vars:TestSlotVariables {
      currentTest().pushUser(location(), line, null, vars);
    }
  / "user:" __ line:SayString {
      currentTest().pushUser(location(), line, null);
    }
  / "user:" __ intent:DottedIdentifier ___ "with" ___ vars:TestSlotVariables {
      currentTest().pushUser(location(), null, intent, vars);
    }
  / "user:" __ intent:DottedIdentifier {
      currentTest().pushUser(location(), null, intent);
    }

/* litexa [request:]
Coming soon!
*/
TestLineRequest
  = "request:" __ name:DottedIdentifier ___ source:AssetName {
    currentTest().pushRequest(location(), name, source);
  }
  / "request:" __ name:DottedIdentifier {
    currentTest().pushRequest(location(), name, null);
  }

TestSlotVariables
  = head:TestSlotVariable __ tail:(TestSlotVariableTail)* {
    tail = tail || [];
    tail.unshift(head);
    return tail;
  }

TestSlotVariableTail
  = "," __ variable:TestSlotVariable {
    return variable;
  }

TestSlotVariable
  = "$" name:Identifier __ '=' __ val:(QuotedString/Integer) {
    return [name, val];
  }

/* litexa [directive:]
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
*/
TestDirectiveStatement
  = "directive:" __ name:DottedIdentifier {
    currentTest().pushExpectation(new lib.ExpectedDirective(location(), name));
  }

/* litexa [alexa:]
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

*/
TestLineAlexa
  = "alexa:" __ stateName:Identifier __ "," __ "e" line:QuotedString {
    currentTest().pushExpectation(new lib.ExpectedState(location(), stateName));
    currentTest().pushExpectation(new lib.ExpectedExactSay(location(), line));
  }
  / "alexa:" __ stateName:Identifier __ "," __ line:TestSaidString {
    currentTest().pushExpectation(new lib.ExpectedState(location(), stateName));
    currentTest().pushExpectation(new lib.ExpectedSay(location(), line));
  }
  / "alexa:" __ stateName:Identifier __ "," __ regex:RegexLiteral {
    currentTest().pushExpectation(new lib.ExpectedState(location(), stateName));
    currentTest().pushExpectation(new lib.ExpectedRegexSay(location(), regex));
  }
  / "alexa:" __ stateName:Identifier  {
    currentTest().pushExpectation(new lib.ExpectedState(location(), stateName));
  }

TestLineAlternate
  = "or" ___ line:QuotedString {
    //currentTest().pushAlexa(line);
    throw new ParserError(location(), "alternates not supported here yet")
  }

/* litexa [@ variable (Testing)]
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
*/
TestLineExpectedDB
  = "@" name:VariableReference __ op:TestComparisonOp __ tail:LineRemainder {
      currentTest().pushExpectation(new lib.ExpectedDB(location(), name, op, tail));
    }
  / "@" name:VariableReference __ "=" __ tail:LineRemainder {
      currentTest().pushDatabaseFix(name, tail);
    }

/* litexa [@ Variable Comparison Operators]
A [@ variable (Testing)](#variable-testing) can use any of these operators:

| | |
| --- | --- |
| `==` | the values should be equal |
| `!=` | the values should *not* be equal |
| `<=` | the reference value should be less than or equal to the expression |
| `>=` | the reference value should be greater than or equal to the expression |
| `<` | the reference value should be less than the expression |
| `>` | the reference value should be greater than the expression |
*/
TestComparisonOp "Comparison Operator"
  = "=="
  / "!="
  / ">="
  / "<="
  / ">"
  / "<"

/* litexa [setRegion]
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

*/
TestSetRegion
  = "setRegion" ___ region:RegionCode {
    currentTest().pushSetRegion(region);
  }

/* litexa [capture]
Takes a snapshot of the skill state at that point in time of
the test. Takes as an argument a name for the capture.

You can write multiple captures in a single test to snapshot
different points in time.

Please see [resume](#resume) for how to use the snapshot.
*/
TestCapture
  = "capture" ___ name:Identifier {
    currentTest().pushCaptureNamedState(location(), name);
  }

/* litexa [resume]
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

*/
TestResume
  = "resume" ___ name:Identifier {
    currentTest().pushResumeNamedState(location(), name);
  }


/* litexa [logStateTraces]

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
*/
TestLogStateTraces
  = "logStateTraces" __ "=" __ flag:BooleanLiteral {
    currentTest().pushSetLogStateTraces(location(), flag);
  }


UtteranceString
  = '"' parts:UtteranceStringPart* '"' {
    return new lib.Utterance(parts);
  }

UtteranceStringPart
  = $(!'"' !'$' !'@' .)+ { return new lib.StringPart(text()); }
  / name:SlotVariableReference { return new lib.SlotReferencePart(name); }


ScreenString
  = parts:ScreenStringParts {
    return new lib.Say(parts);
  }

ScreenStringParts
  = '"' parts:ScreenStringPart* '"' {
    return parts;
  }

ScreenStringPart
  = TemplateStringClearPart
  / TemplateStringExpressionPart
  / TemplateStringSlotPart
  / TemplateStringFontSize
  / TemplateStringDatabaseCallPart
  / TemplateStringDatabasePart
  / TemplateStringTaggedPart

/* litexa [Say String]
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
*/
SayString
  = parts:SayStringParts {
    return new lib.Say(parts);
  }

SayStringParts
  = '"' parts:SayStringPart* '"' {
    return parts;
  }

SayStringPart
  = TemplateStringClearPart
  / TemplateStringEscapedCharacterPart
  / TemplateStringSoundEffectPart
  / TemplateStringExpressionPart
  / TemplateStringSlotPart
  / TemplateStringDatabaseCallPart
  / TemplateStringDatabasePart
  / TemplateStringStaticPart
  / TemplateStringPausePart
  / TemplateStringInterjectionPart
  / TemplateStringTaggedPart


TemplateStringClearPart
  = $(!'"' !'$' !'@' !'{' !'<' !'\\' !'DEPLOY' .)+ { return new lib.StringPart(text()); }


TemplateStringEscapedCharacterPart
  = '\\$' { return new lib.StringPart('$'); }
  / '\\@' { return new lib.StringPart('@'); }
  / '\\<' { return new lib.StringPart('<'); }
  / '\\\\' { return new lib.StringPart('\\'); }
  / '\\' symbol:'{' {
    // note: pegjs parser had trouble with using the symbol character in the action
    return new lib.StringPart(symbol);
  }

TemplateStringExpressionPart
  = '{' __ func:ExpressionString __ '}' { return new lib.JavaScriptPart(func); }

TemplateStringSlotPart
  = name:SlotVariableReference { return new lib.SlotReferencePart(name); }

TemplateStringDatabasePart
  = '@' name:VariableReference {
    return new lib.DatabaseReferencePart(name);
  }

/* litexa [DEPLOY variable]

Can reference a property of the optional `DEPLOY` object that can be defined in your
Litexa configuration file. Assuming that this `DEPLOY` object was defined on your
`development` deployment target:

```javascript
development: {
  DEPLOY: { LOG_LEVEL: 'verbose' }
  // other configuration...
}
```

Then the below condition would be true while testing or running the skill for the
`development` target:

```coffeescript
launch
  if DEPLOY.LOG_LEVEL == "verbose"
    log "verbose logging enabled"
```

Please see the Variables and Expressions chapter for how to define and use `DEPLOY`
variables, and their practical applications.

Note that you cannot reference the `DEPLOY` object by itself; you must reference
a field on the `DEPLOY` object.
*/
TemplateStringStaticPart
  = 'DEPLOY.' name:VariableReference {
    return new lib.StaticVariableReferencePart(name);
  }

TemplateStringDatabaseCallPart
  = '@' name:VariableReference args:FunctionCallArguments {
    return new lib.DatabaseReferenceCallPart(name, args);
  }

TemplateStringPausePart
  = '<...' __ time:Integer unit:('ms'/'s') __ '>' {
    return new lib.TagPart(skill, location(), '...', null, time + unit);
  }

TemplateStringFontSize
  = '<f' __ size:Integer __ text:TagText '>' {
    return new lib.TagPart(skill, location(), 'fontsize', text, size );
  }

TemplateStringInterjectionPart
  = '<!' __ text:TagText '>' __ punctuation:TagPunctuation {
    if (text.includes('&')) {
      throw new ParserError(location(), `Interjection <!${text}> contains an invalid ampersand character.`);
    }
    return new lib.TagPart(skill, location(), '!', text + punctuation );
  }
  / '<!' __ text:TagText '>' {
    if (text.includes('&')) {
      throw new ParserError(location(), `Interjection <!${text}> contains an invalid ampersand character.`);
    }
    return new lib.TagPart(skill, location(), '!', text );
  }

TemplateStringSoundEffectPart
  = '<sfx' __ name:AssetName __ '>' {
    return new lib.TagPart(skill, location(), 'sfx', name );
  }
  / '<sfx' __ name:AssetURL __ '>' {
    return new lib.TagPart(skill, location(), 'sfx', name );
  }
  / '<sfx' __ name:AssetSoundBank __ '>' {
    return new lib.TagPart(skill, location(), 'sfx', name );
  }

TemplateStringTaggedPart
  = '<' code:TagCode __ text:TagText '>' {
    return new lib.TagPart(skill, location(), code, text);
  }

TagPunctuation
  = ( ',' / '.' / '!' / '?' )+ { return text(); }

TagCode
  = $(!'>' !' ' !'\t' .)+ { return text(); }

TagText
  = $(!'>' .)* { return text(); }


TestSaidString
  = '"' parts:TestSaidStringPart* '"' {
    return new lib.Say(parts);
  }

TestSaidStringPart
  = $(!'"' !'@' !'<' .)+ { return new lib.StringPart(text()); }
  / '$' name:AssetName '>' { return new lib.AssetNamePart(name); }
  / '@' name:VariableReference { return new lib.DatabaseReferencePart(name); }
  / '<' name:AssetName '>' { return new lib.AssetNamePart(name); }
  / TemplateStringEscapedCharacterPart
  / TemplateStringSoundEffectPart
  / TemplateStringExpressionPart
  / TemplateStringInterjectionPart
  / TemplateStringPausePart
  / TemplateStringTaggedPart


VariableReference
  = name:ExistingIdentifier children:VariableReferenceTail* {
    return new lib.VariableReference(name, children);
  }

VariableReferenceTail
  = "[" __ number:(Digit*) __ "]" { return new lib.VariableArrayAccess(number); }
  / "[" __ index:QuotedString __ "]" { return new lib.VariableArrayAccess(index); }
  / "." name:Identifier { return new lib.VariableMemberAccess(name); }


SlotVariableReference
  = '$' name:SlotIdentifier badnumber:Integer {
    throw new ParserError(location(), "`$" + name + badnumber + "` is not a valid slot name. You may only use letters and the `-` character");
  }
  / '$' name:SlotIdentifier children:VariableReferenceTail* {
    return new lib.VariableReference(name, children);
  }
  / '$' name:MostCharacters* children:VariableReferenceTail* {
    throw new ParserError(location(), "`$" + name.join('') + "` is not a valid slot name. You may only use letters and the `-` character");
  }

SlotIdentifier "Slot Identifier"
  = ([a-z]/[A-Z]/'-')+ { return text(); }


FunctionCallStatement
  = call:FunctionCall {
    pushCode( location(), new lib.EvaluateExpression(call) );
  }

/* litexa [Expression]
Coming soon!

For now, please reference the Variables and Expressions chapter in the Book.
*/
/* litexa [Inline Function]
Coming soon!
*/
ExpressionString "Expression"
  = root:LogicalExpr {
    return new lib.Expression(location(), root);
  }

LogicalExpr
  = left:ComparisonExpr tail:(LogicalExprTail)+ {
      return tail.reduce(function(res, right){
        return new lib.BinaryExpression(location(), res, right.op, right.val);
      }, left);
    }
  / ComparisonExpr

LogicalExprTail
  = __ op:ExpressionBooleanOperator __ val:ComparisonExpr {
    return {op:op, val:val}; }

ExpressionBooleanOperator "Expression and/or operator"
  = 'and' / 'or'

ComparisonExpr
  = left:AdditiveExpr tail:(ComparisonExprTail)+ {
      return tail.reduce(function(res, right){
        return new lib.BinaryExpression(location(), res, right.op, right.val);
      }, left);
    }
  / AdditiveExpr

ComparisonExprTail "Expression Comparison Operator"
  = __ op:ExpressionCompareOperator __ val:AdditiveExpr {
      return {op:op, val:val};
    }

ExpressionCompareOperator "Expression Comparison Operator"
  = ">="
  / "<="
  / "!="
  / "=="
  / ">"
  / "<"

AdditiveExpr
  = left:MultiplicativeExpr tail:(AdditiveExprTail)+ {
      return tail.reduce(function(res, right){
        return new lib.BinaryExpression(location(), res, right.op, right.val);
      }, left);
    }
  / MultiplicativeExpr

AdditiveExprTail "Expression Operator"
  = __ op:("+"/"-") __ val:MultiplicativeExpr {
      return {op:op, val:val};
    }

MultiplicativeExpr
  = op:"not" ___ val:MultiplicativeExpr {
      return new lib.UnaryExpression(location(), op, val);
    }
  / left:ExpressionValue tail:(MultiplicativeExprTail)+ {
      return tail.reduce(function(res, right){
        return new lib.BinaryExpression(location(), res, right.op, right.val);
      }, left);
    }
  / ExpressionValue

MultiplicativeExprTail "Expression Operator"
  = __ op:("*"/"/") __ val:ExpressionValue {
      return {op:op, val:val};
    }

ExpressionValue
  = "(" __ val:LogicalExpr __  ")" { return val; }
  / FunctionCall
  / '@' name:VariableReference {
    return new lib.DatabaseReferencePart(name);
  }
  / 'DEPLOY.' name:VariableReference {
    return new lib.StaticVariableReferencePart(name);
  }
  / name:SlotVariableReference {
    return new lib.SlotReferencePart(name);
  }
  / StringLiteral
  / SingleQuotedStringLiteral
  / BooleanLiteral
  / LocalVariableReference
  / Number

LocalVariableReference
  = name:VariableReference {
    return new lib.LocalVariableReference(location(), name);
  }

FunctionCall
  = name:VariableReference __ args:FunctionCallArguments {
      return new lib.LocalExpressionCall(location(), name, args );
    }
  / '@' name:VariableReference __ args:FunctionCallArguments {
      return new lib.DBExpressionCall(location(), name, args );
    }


FunctionCallArguments
  = '(' __ head:ExpressionString tail:(FunctionCallArgumentsTail)+ __ ')' {
      tail.unshift(head);
      return tail;
    }
  / '(' __ arg:ExpressionString __ ')' { return [arg]; }
  / '()' { return []; }
  / '(' __ ')' { return []; }

FunctionCallArgumentsTail
  = __ ',' __ arg:ExpressionString {
    return arg;
  }

StringLiteral
  = '"' str:(!'"' .)* '"' { return text(); }

SingleQuotedStringLiteral
  = "'" str:(!"'" .)* "'" { return text(); }


StringLiteralList
  = head:StringLiteral __ tail:StringLiteralListTail* {
    tail = tail || [];
    tail.unshift(head);
    return tail;
  }

StringLiteralListTail
  = __ ',' __r str:StringLiteral { return str; }

AssetName
  = ['"]? name:AssetNameDottedSegment+ type:AssetNameWord ['"]? {
    return new lib.AssetName(location(), name.join('.'), type, skill, true);
  }

AssetNameDottedSegment
  = name:AssetNameWord '.' {
    return name;
  }

AssetNameWord
  = ([a-z] / [A-Z] / [0-9] / '_' / '-' / '/')+ {
    return text();
  }

AssetSoundBank
  = soundBankPath:AssetSoundBankPath {
    return new lib.AssetName(location(), soundBankPath, 'mp3', skill, false);
  }

AssetSoundBankPath
  = ['"]? prefix:("soundbank://") soundBankStr:AssetNameWord ['"]? {
    return text().replace(/['"]+/g, '');
  }

AssetURL
  = urlPath:AssetURLPath {
    const index = urlPath.lastIndexOf("/");
    const fileName = urlPath.substr(index + 1);

    const typeIndex = fileName.lastIndexOf(".");
    let fileType;

    if (typeIndex != -1) {
      fileType = fileName.substr(typeIndex + 1).toLowerCase();
    } else {
      throw new ParserError(location(), "could not detect the file type from the asset url " + text());
    }

    return new lib.AssetName(location(), urlPath, fileType, skill, false);
  }

AssetURLPath
  = ['"]? prefix:("http://" / "https://") rest:([a-zA-Z0-9:%./\+$~#=\(\)\-\_&?!~])* ['"]? {
    return text().replace(/['"]+/g, '');
  }

 /* litexa [jsonFiles]
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
 */

JsonFileName
  = name:AssetNameDottedSegment+ type:'json' {
    return lib.parseJsonFile(location(), `${name}.${type}`, skill);
  }
  / '"' name:AssetNameDottedSegment+ type:'json' '"' {
    return lib.parseJsonFile(location(), `${name}.${type}`, skill);
  }

FileFunctionReference
  = parts:(AssetNameWord '.')+ extension:CodeExtension ':' func:AssetNameWord {
    var p = []
    for (var i=0; i<parts.length; ++i) {
      p.push(parts[i][0]);
    }
    var filename = p.join('.') + '.' + extension;
    return new lib.FileFunctionReference(location(), filename, func);
  }

CodeExtension
  = 'coffee'
  / 'js'


NewDataTableStatement
  = "TABLE" ___ name:Identifier ___ "=" ___ header:Identifier __ tail:DataTableHeaderTail* {
    testLead(location(), "");
    tail = tail || [];
    tail.unshift(header);
    pushDataTable(name, tail);
  }

DataTableHeaderTail
  = "," __ name:Identifier { return name; }

DataTableRowStatement
  = item:DataTableItem __ tail:(DataTableItemTail)* {
    tail = tail || [];
    tail.unshift(item);
    stack[1].target.pushRow(tail);
  }

DataTableItem
  = $(!'|' !LineTerminatorSequence .)*

DataTableItemTail
  = "|" __ item:DataTableItem { return item; }


LineRemainder
  = tail:$(!EndOfStatementSequence .)*


LineTerminatorSequence "End of Line"
  = "\n"
  / "\r\n"
  / "\r"
  / "\u2028"
  / "\u2029"


WhiteSpace "whitespace"
  = "\t"
  / "\v"
  / "\f"
  / " "
//  / "\u00A0"
  / "\uFEFF"
  / Zs

__ "white space"
  = WhiteSpace*

___ "required white space"
  = WhiteSpace+

__r "white space including line breaks"
  = (WhiteSpace/LineTerminatorSequence)*

QuotedString
  = '"' __ inner:$(!'"' .)* '"' {
    return inner;
  }


RegionCode
  = language:(ASCIICasedCharacter ASCIICasedCharacter) '-' country:(ASCIICasedCharacter ASCIICasedCharacter) {
      return text();
    }
  / (ASCIICasedCharacter ASCIICasedCharacter) {
      return text();
    }


ASCIICasedCharacter
  = [a-z] / [A-Z]


Number
  = Float / Integer

Integer
  = '-' Digit+ {
    return parseInt(text());
  }
  / Digit+ {
    return parseInt(text());
  }

Float
  = '-' Digit+ '.' Digit+ {
    return parseFloat(text());
  }
  / Digit+ '.' Digit+ {
    return parseFloat(text());
  }


BooleanLiteral
  = "true" { return true; }
  / "false" { return false; }


/* litexa [Identifier]
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
*/

Identifier "Identifier"
  = !(ReservedWord ___) word:IdentifierString {
    return word;
  }
  / ReservedWord {
    console.log((new Error).stack);
    throw new ParserError(location(), "the word " + text() + " is reserved and cannot be used as an identifier");
  }

IdentifierString "Identifier"
  = IdentifierStart IdentifierTail* { return text(); }

IdentifierStart
  = Ll / Lu / ULl / Lo / '_'

IdentifierTail
  = Ll / Lu / Nd / ULl / Lo / '_'

DottedIdentifier
  = Identifier tail:DottedIdentifierTail+ {
    return text();
  }
  / Identifier {
    return text();
  }

DottedIdentifierTail
  = "." Identifier {
    return text();
  }


ExistingIdentifier
  = word:IdentifierString {
    return word;
  }

ExistingDottedIdentifier
  = ExistingIdentifier tail:DottedIdentifierTail+ {
    return text();
  }
  / ExistingIdentifier {
    return text();
  }

StateName
  = ReservedWord StateNameTailCharacters+ {
    return text();
  }
  / ReservedWord {
    if (text() == "launch" || text() == "global") {
      return text();
    }
    throw new ParserError(location(), "the word `" + text() + "` is reserved and cannot be used as a state name");
  }
  / ( Ll / Lu / ULl / Lo ) StateNameTailCharacters* {
    return text();
  }

StateNameTailCharacters
  = ( Ll / Lu / ULl / Lo / '_' / Nd )

HexColor
  = HexPair HexPair HexPair { return text(); }

HexPair
  = HexDigit HexDigit

HexDigit "hex digit"
  = ( [0-9] / [A-F] )


/* litexa [Reserved Word]
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
*/
ReservedWord "reserved keyword"
  = "capture"
  / "card"
  / "define"
  / "directive"
  / "END"
  / "for"
  / "in"
  / "if"
  / "else"
  / "global"
  / "launch"
  / "LISTEN"
  / "microphone"
  / "events"
  / "local"
  / "log"
  / "logStateTraces"
  / "metric"
  / "or"
  / "otherwise"
  / "pronounce"
  / "quit"
  / "reprompt"
  / "resume"
  / "say"
  / "set"
  / "setRegion"
  / "setResponseSpacing"
  / "switch"
  / "TEST"
  / "then"
  / "unless"
  / "wait"
  / "when"
  / "with"

MostCharacters "Most any character" = Ll / Lu / Nd / ULl / Lo / '_'

NonAsciiLetterCharacter "Non ascii letter character" = Nd / ULl / Lo

// Letter, Lowercase
Ll "lower case letter" = [a-z]

ULl "non ascii letter" = [\u0061-\u007A\u00B5\u00DF-\u00F6\u00F8-\u00FF\u0101\u0103\u0105\u0107\u0109\u010B\u010D\u010F\u0111\u0113\u0115\u0117\u0119\u011B\u011D\u011F\u0121\u0123\u0125\u0127\u0129\u012B\u012D\u012F\u0131\u0133\u0135\u0137-\u0138\u013A\u013C\u013E\u0140\u0142\u0144\u0146\u0148-\u0149\u014B\u014D\u014F\u0151\u0153\u0155\u0157\u0159\u015B\u015D\u015F\u0161\u0163\u0165\u0167\u0169\u016B\u016D\u016F\u0171\u0173\u0175\u0177\u017A\u017C\u017E-\u0180\u0183\u0185\u0188\u018C-\u018D\u0192\u0195\u0199-\u019B\u019E\u01A1\u01A3\u01A5\u01A8\u01AA-\u01AB\u01AD\u01B0\u01B4\u01B6\u01B9-\u01BA\u01BD-\u01BF\u01C6\u01C9\u01CC\u01CE\u01D0\u01D2\u01D4\u01D6\u01D8\u01DA\u01DC-\u01DD\u01DF\u01E1\u01E3\u01E5\u01E7\u01E9\u01EB\u01ED\u01EF-\u01F0\u01F3\u01F5\u01F9\u01FB\u01FD\u01FF\u0201\u0203\u0205\u0207\u0209\u020B\u020D\u020F\u0211\u0213\u0215\u0217\u0219\u021B\u021D\u021F\u0221\u0223\u0225\u0227\u0229\u022B\u022D\u022F\u0231\u0233-\u0239\u023C\u023F-\u0240\u0242\u0247\u0249\u024B\u024D\u024F-\u0293\u0295-\u02AF\u0371\u0373\u0377\u037B-\u037D\u0390\u03AC-\u03CE\u03D0-\u03D1\u03D5-\u03D7\u03D9\u03DB\u03DD\u03DF\u03E1\u03E3\u03E5\u03E7\u03E9\u03EB\u03ED\u03EF-\u03F3\u03F5\u03F8\u03FB-\u03FC\u0430-\u045F\u0461\u0463\u0465\u0467\u0469\u046B\u046D\u046F\u0471\u0473\u0475\u0477\u0479\u047B\u047D\u047F\u0481\u048B\u048D\u048F\u0491\u0493\u0495\u0497\u0499\u049B\u049D\u049F\u04A1\u04A3\u04A5\u04A7\u04A9\u04AB\u04AD\u04AF\u04B1\u04B3\u04B5\u04B7\u04B9\u04BB\u04BD\u04BF\u04C2\u04C4\u04C6\u04C8\u04CA\u04CC\u04CE-\u04CF\u04D1\u04D3\u04D5\u04D7\u04D9\u04DB\u04DD\u04DF\u04E1\u04E3\u04E5\u04E7\u04E9\u04EB\u04ED\u04EF\u04F1\u04F3\u04F5\u04F7\u04F9\u04FB\u04FD\u04FF\u0501\u0503\u0505\u0507\u0509\u050B\u050D\u050F\u0511\u0513\u0515\u0517\u0519\u051B\u051D\u051F\u0521\u0523\u0525\u0527\u0529\u052B\u052D\u052F\u0561-\u0587\u13F8-\u13FD\u1D00-\u1D2B\u1D6B-\u1D77\u1D79-\u1D9A\u1E01\u1E03\u1E05\u1E07\u1E09\u1E0B\u1E0D\u1E0F\u1E11\u1E13\u1E15\u1E17\u1E19\u1E1B\u1E1D\u1E1F\u1E21\u1E23\u1E25\u1E27\u1E29\u1E2B\u1E2D\u1E2F\u1E31\u1E33\u1E35\u1E37\u1E39\u1E3B\u1E3D\u1E3F\u1E41\u1E43\u1E45\u1E47\u1E49\u1E4B\u1E4D\u1E4F\u1E51\u1E53\u1E55\u1E57\u1E59\u1E5B\u1E5D\u1E5F\u1E61\u1E63\u1E65\u1E67\u1E69\u1E6B\u1E6D\u1E6F\u1E71\u1E73\u1E75\u1E77\u1E79\u1E7B\u1E7D\u1E7F\u1E81\u1E83\u1E85\u1E87\u1E89\u1E8B\u1E8D\u1E8F\u1E91\u1E93\u1E95-\u1E9D\u1E9F\u1EA1\u1EA3\u1EA5\u1EA7\u1EA9\u1EAB\u1EAD\u1EAF\u1EB1\u1EB3\u1EB5\u1EB7\u1EB9\u1EBB\u1EBD\u1EBF\u1EC1\u1EC3\u1EC5\u1EC7\u1EC9\u1ECB\u1ECD\u1ECF\u1ED1\u1ED3\u1ED5\u1ED7\u1ED9\u1EDB\u1EDD\u1EDF\u1EE1\u1EE3\u1EE5\u1EE7\u1EE9\u1EEB\u1EED\u1EEF\u1EF1\u1EF3\u1EF5\u1EF7\u1EF9\u1EFB\u1EFD\u1EFF-\u1F07\u1F10-\u1F15\u1F20-\u1F27\u1F30-\u1F37\u1F40-\u1F45\u1F50-\u1F57\u1F60-\u1F67\u1F70-\u1F7D\u1F80-\u1F87\u1F90-\u1F97\u1FA0-\u1FA7\u1FB0-\u1FB4\u1FB6-\u1FB7\u1FBE\u1FC2-\u1FC4\u1FC6-\u1FC7\u1FD0-\u1FD3\u1FD6-\u1FD7\u1FE0-\u1FE7\u1FF2-\u1FF4\u1FF6-\u1FF7\u210A\u210E-\u210F\u2113\u212F\u2134\u2139\u213C-\u213D\u2146-\u2149\u214E\u2184\u2C30-\u2C5E\u2C61\u2C65-\u2C66\u2C68\u2C6A\u2C6C\u2C71\u2C73-\u2C74\u2C76-\u2C7B\u2C81\u2C83\u2C85\u2C87\u2C89\u2C8B\u2C8D\u2C8F\u2C91\u2C93\u2C95\u2C97\u2C99\u2C9B\u2C9D\u2C9F\u2CA1\u2CA3\u2CA5\u2CA7\u2CA9\u2CAB\u2CAD\u2CAF\u2CB1\u2CB3\u2CB5\u2CB7\u2CB9\u2CBB\u2CBD\u2CBF\u2CC1\u2CC3\u2CC5\u2CC7\u2CC9\u2CCB\u2CCD\u2CCF\u2CD1\u2CD3\u2CD5\u2CD7\u2CD9\u2CDB\u2CDD\u2CDF\u2CE1\u2CE3-\u2CE4\u2CEC\u2CEE\u2CF3\u2D00-\u2D25\u2D27\u2D2D\uA641\uA643\uA645\uA647\uA649\uA64B\uA64D\uA64F\uA651\uA653\uA655\uA657\uA659\uA65B\uA65D\uA65F\uA661\uA663\uA665\uA667\uA669\uA66B\uA66D\uA681\uA683\uA685\uA687\uA689\uA68B\uA68D\uA68F\uA691\uA693\uA695\uA697\uA699\uA69B\uA723\uA725\uA727\uA729\uA72B\uA72D\uA72F-\uA731\uA733\uA735\uA737\uA739\uA73B\uA73D\uA73F\uA741\uA743\uA745\uA747\uA749\uA74B\uA74D\uA74F\uA751\uA753\uA755\uA757\uA759\uA75B\uA75D\uA75F\uA761\uA763\uA765\uA767\uA769\uA76B\uA76D\uA76F\uA771-\uA778\uA77A\uA77C\uA77F\uA781\uA783\uA785\uA787\uA78C\uA78E\uA791\uA793-\uA795\uA797\uA799\uA79B\uA79D\uA79F\uA7A1\uA7A3\uA7A5\uA7A7\uA7A9\uA7B5\uA7B7\uA7FA\uAB30-\uAB5A\uAB60-\uAB65\uAB70-\uABBF\uFB00-\uFB06\uFB13-\uFB17\uFF41-\uFF5A]

// Letter, Modifier
Lm = [\u02B0-\u02C1\u02C6-\u02D1\u02E0-\u02E4\u02EC\u02EE\u0374\u037A\u0559\u0640\u06E5-\u06E6\u07F4-\u07F5\u07FA\u081A\u0824\u0828\u0971\u0E46\u0EC6\u10FC\u17D7\u1843\u1AA7\u1C78-\u1C7D\u1D2C-\u1D6A\u1D78\u1D9B-\u1DBF\u2071\u207F\u2090-\u209C\u2C7C-\u2C7D\u2D6F\u2E2F\u3005\u3031-\u3035\u303B\u309D-\u309E\u30FC-\u30FE\uA015\uA4F8-\uA4FD\uA60C\uA67F\uA69C-\uA69D\uA717-\uA71F\uA770\uA788\uA7F8-\uA7F9\uA9CF\uA9E6\uAA70\uAADD\uAAF3-\uAAF4\uAB5C-\uAB5F\uFF70\uFF9E-\uFF9F]

// Letter, Other
Lo "other letters" = [\u00AA\u00BA\u01BB\u01C0-\u01C3\u0294\u05D0-\u05EA\u05F0-\u05F2\u0620-\u063F\u0641-\u064A\u066E-\u066F\u0671-\u06D3\u06D5\u06EE-\u06EF\u06FA-\u06FC\u06FF\u0710\u0712-\u072F\u074D-\u07A5\u07B1\u07CA-\u07EA\u0800-\u0815\u0840-\u0858\u08A0-\u08B4\u0904-\u0939\u093D\u0950\u0958-\u0961\u0972-\u0980\u0985-\u098C\u098F-\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09BD\u09CE\u09DC-\u09DD\u09DF-\u09E1\u09F0-\u09F1\u0A05-\u0A0A\u0A0F-\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32-\u0A33\u0A35-\u0A36\u0A38-\u0A39\u0A59-\u0A5C\u0A5E\u0A72-\u0A74\u0A85-\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2-\u0AB3\u0AB5-\u0AB9\u0ABD\u0AD0\u0AE0-\u0AE1\u0AF9\u0B05-\u0B0C\u0B0F-\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32-\u0B33\u0B35-\u0B39\u0B3D\u0B5C-\u0B5D\u0B5F-\u0B61\u0B71\u0B83\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99-\u0B9A\u0B9C\u0B9E-\u0B9F\u0BA3-\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB9\u0BD0\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C39\u0C3D\u0C58-\u0C5A\u0C60-\u0C61\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CBD\u0CDE\u0CE0-\u0CE1\u0CF1-\u0CF2\u0D05-\u0D0C\u0D0E-\u0D10\u0D12-\u0D3A\u0D3D\u0D4E\u0D5F-\u0D61\u0D7A-\u0D7F\u0D85-\u0D96\u0D9A-\u0DB1\u0DB3-\u0DBB\u0DBD\u0DC0-\u0DC6\u0E01-\u0E30\u0E32-\u0E33\u0E40-\u0E45\u0E81-\u0E82\u0E84\u0E87-\u0E88\u0E8A\u0E8D\u0E94-\u0E97\u0E99-\u0E9F\u0EA1-\u0EA3\u0EA5\u0EA7\u0EAA-\u0EAB\u0EAD-\u0EB0\u0EB2-\u0EB3\u0EBD\u0EC0-\u0EC4\u0EDC-\u0EDF\u0F00\u0F40-\u0F47\u0F49-\u0F6C\u0F88-\u0F8C\u1000-\u102A\u103F\u1050-\u1055\u105A-\u105D\u1061\u1065-\u1066\u106E-\u1070\u1075-\u1081\u108E\u10D0-\u10FA\u10FD-\u1248\u124A-\u124D\u1250-\u1256\u1258\u125A-\u125D\u1260-\u1288\u128A-\u128D\u1290-\u12B0\u12B2-\u12B5\u12B8-\u12BE\u12C0\u12C2-\u12C5\u12C8-\u12D6\u12D8-\u1310\u1312-\u1315\u1318-\u135A\u1380-\u138F\u1401-\u166C\u166F-\u167F\u1681-\u169A\u16A0-\u16EA\u16F1-\u16F8\u1700-\u170C\u170E-\u1711\u1720-\u1731\u1740-\u1751\u1760-\u176C\u176E-\u1770\u1780-\u17B3\u17DC\u1820-\u1842\u1844-\u1877\u1880-\u18A8\u18AA\u18B0-\u18F5\u1900-\u191E\u1950-\u196D\u1970-\u1974\u1980-\u19AB\u19B0-\u19C9\u1A00-\u1A16\u1A20-\u1A54\u1B05-\u1B33\u1B45-\u1B4B\u1B83-\u1BA0\u1BAE-\u1BAF\u1BBA-\u1BE5\u1C00-\u1C23\u1C4D-\u1C4F\u1C5A-\u1C77\u1CE9-\u1CEC\u1CEE-\u1CF1\u1CF5-\u1CF6\u2135-\u2138\u2D30-\u2D67\u2D80-\u2D96\u2DA0-\u2DA6\u2DA8-\u2DAE\u2DB0-\u2DB6\u2DB8-\u2DBE\u2DC0-\u2DC6\u2DC8-\u2DCE\u2DD0-\u2DD6\u2DD8-\u2DDE\u3006\u303C\u3041-\u3096\u309F\u30A1-\u30FA\u30FF\u3105-\u312D\u3131-\u318E\u31A0-\u31BA\u31F0-\u31FF\u3400-\u4DB5\u4E00-\u9FD5\uA000-\uA014\uA016-\uA48C\uA4D0-\uA4F7\uA500-\uA60B\uA610-\uA61F\uA62A-\uA62B\uA66E\uA6A0-\uA6E5\uA78F\uA7F7\uA7FB-\uA801\uA803-\uA805\uA807-\uA80A\uA80C-\uA822\uA840-\uA873\uA882-\uA8B3\uA8F2-\uA8F7\uA8FB\uA8FD\uA90A-\uA925\uA930-\uA946\uA960-\uA97C\uA984-\uA9B2\uA9E0-\uA9E4\uA9E7-\uA9EF\uA9FA-\uA9FE\uAA00-\uAA28\uAA40-\uAA42\uAA44-\uAA4B\uAA60-\uAA6F\uAA71-\uAA76\uAA7A\uAA7E-\uAAAF\uAAB1\uAAB5-\uAAB6\uAAB9-\uAABD\uAAC0\uAAC2\uAADB-\uAADC\uAAE0-\uAAEA\uAAF2\uAB01-\uAB06\uAB09-\uAB0E\uAB11-\uAB16\uAB20-\uAB26\uAB28-\uAB2E\uABC0-\uABE2\uAC00-\uD7A3\uD7B0-\uD7C6\uD7CB-\uD7FB\uF900-\uFA6D\uFA70-\uFAD9\uFB1D\uFB1F-\uFB28\uFB2A-\uFB36\uFB38-\uFB3C\uFB3E\uFB40-\uFB41\uFB43-\uFB44\uFB46-\uFBB1\uFBD3-\uFD3D\uFD50-\uFD8F\uFD92-\uFDC7\uFDF0-\uFDFB\uFE70-\uFE74\uFE76-\uFEFC\uFF66-\uFF6F\uFF71-\uFF9D\uFFA0-\uFFBE\uFFC2-\uFFC7\uFFCA-\uFFCF\uFFD2-\uFFD7\uFFDA-\uFFDC]

// Letter, Titlecase
Lt = [\u01C5\u01C8\u01CB\u01F2\u1F88-\u1F8F\u1F98-\u1F9F\u1FA8-\u1FAF\u1FBC\u1FCC\u1FFC]

// Letter, Uppercase
Lu "upper case letter" = [A-Z]

ULu "extended letters" = [\u0041-\u005A\u00C0-\u00D6\u00D8-\u00DE\u0100\u0102\u0104\u0106\u0108\u010A\u010C\u010E\u0110\u0112\u0114\u0116\u0118\u011A\u011C\u011E\u0120\u0122\u0124\u0126\u0128\u012A\u012C\u012E\u0130\u0132\u0134\u0136\u0139\u013B\u013D\u013F\u0141\u0143\u0145\u0147\u014A\u014C\u014E\u0150\u0152\u0154\u0156\u0158\u015A\u015C\u015E\u0160\u0162\u0164\u0166\u0168\u016A\u016C\u016E\u0170\u0172\u0174\u0176\u0178-\u0179\u017B\u017D\u0181-\u0182\u0184\u0186-\u0187\u0189-\u018B\u018E-\u0191\u0193-\u0194\u0196-\u0198\u019C-\u019D\u019F-\u01A0\u01A2\u01A4\u01A6-\u01A7\u01A9\u01AC\u01AE-\u01AF\u01B1-\u01B3\u01B5\u01B7-\u01B8\u01BC\u01C4\u01C7\u01CA\u01CD\u01CF\u01D1\u01D3\u01D5\u01D7\u01D9\u01DB\u01DE\u01E0\u01E2\u01E4\u01E6\u01E8\u01EA\u01EC\u01EE\u01F1\u01F4\u01F6-\u01F8\u01FA\u01FC\u01FE\u0200\u0202\u0204\u0206\u0208\u020A\u020C\u020E\u0210\u0212\u0214\u0216\u0218\u021A\u021C\u021E\u0220\u0222\u0224\u0226\u0228\u022A\u022C\u022E\u0230\u0232\u023A-\u023B\u023D-\u023E\u0241\u0243-\u0246\u0248\u024A\u024C\u024E\u0370\u0372\u0376\u037F\u0386\u0388-\u038A\u038C\u038E-\u038F\u0391-\u03A1\u03A3-\u03AB\u03CF\u03D2-\u03D4\u03D8\u03DA\u03DC\u03DE\u03E0\u03E2\u03E4\u03E6\u03E8\u03EA\u03EC\u03EE\u03F4\u03F7\u03F9-\u03FA\u03FD-\u042F\u0460\u0462\u0464\u0466\u0468\u046A\u046C\u046E\u0470\u0472\u0474\u0476\u0478\u047A\u047C\u047E\u0480\u048A\u048C\u048E\u0490\u0492\u0494\u0496\u0498\u049A\u049C\u049E\u04A0\u04A2\u04A4\u04A6\u04A8\u04AA\u04AC\u04AE\u04B0\u04B2\u04B4\u04B6\u04B8\u04BA\u04BC\u04BE\u04C0-\u04C1\u04C3\u04C5\u04C7\u04C9\u04CB\u04CD\u04D0\u04D2\u04D4\u04D6\u04D8\u04DA\u04DC\u04DE\u04E0\u04E2\u04E4\u04E6\u04E8\u04EA\u04EC\u04EE\u04F0\u04F2\u04F4\u04F6\u04F8\u04FA\u04FC\u04FE\u0500\u0502\u0504\u0506\u0508\u050A\u050C\u050E\u0510\u0512\u0514\u0516\u0518\u051A\u051C\u051E\u0520\u0522\u0524\u0526\u0528\u052A\u052C\u052E\u0531-\u0556\u10A0-\u10C5\u10C7\u10CD\u13A0-\u13F5\u1E00\u1E02\u1E04\u1E06\u1E08\u1E0A\u1E0C\u1E0E\u1E10\u1E12\u1E14\u1E16\u1E18\u1E1A\u1E1C\u1E1E\u1E20\u1E22\u1E24\u1E26\u1E28\u1E2A\u1E2C\u1E2E\u1E30\u1E32\u1E34\u1E36\u1E38\u1E3A\u1E3C\u1E3E\u1E40\u1E42\u1E44\u1E46\u1E48\u1E4A\u1E4C\u1E4E\u1E50\u1E52\u1E54\u1E56\u1E58\u1E5A\u1E5C\u1E5E\u1E60\u1E62\u1E64\u1E66\u1E68\u1E6A\u1E6C\u1E6E\u1E70\u1E72\u1E74\u1E76\u1E78\u1E7A\u1E7C\u1E7E\u1E80\u1E82\u1E84\u1E86\u1E88\u1E8A\u1E8C\u1E8E\u1E90\u1E92\u1E94\u1E9E\u1EA0\u1EA2\u1EA4\u1EA6\u1EA8\u1EAA\u1EAC\u1EAE\u1EB0\u1EB2\u1EB4\u1EB6\u1EB8\u1EBA\u1EBC\u1EBE\u1EC0\u1EC2\u1EC4\u1EC6\u1EC8\u1ECA\u1ECC\u1ECE\u1ED0\u1ED2\u1ED4\u1ED6\u1ED8\u1EDA\u1EDC\u1EDE\u1EE0\u1EE2\u1EE4\u1EE6\u1EE8\u1EEA\u1EEC\u1EEE\u1EF0\u1EF2\u1EF4\u1EF6\u1EF8\u1EFA\u1EFC\u1EFE\u1F08-\u1F0F\u1F18-\u1F1D\u1F28-\u1F2F\u1F38-\u1F3F\u1F48-\u1F4D\u1F59\u1F5B\u1F5D\u1F5F\u1F68-\u1F6F\u1FB8-\u1FBB\u1FC8-\u1FCB\u1FD8-\u1FDB\u1FE8-\u1FEC\u1FF8-\u1FFB\u2102\u2107\u210B-\u210D\u2110-\u2112\u2115\u2119-\u211D\u2124\u2126\u2128\u212A-\u212D\u2130-\u2133\u213E-\u213F\u2145\u2183\u2C00-\u2C2E\u2C60\u2C62-\u2C64\u2C67\u2C69\u2C6B\u2C6D-\u2C70\u2C72\u2C75\u2C7E-\u2C80\u2C82\u2C84\u2C86\u2C88\u2C8A\u2C8C\u2C8E\u2C90\u2C92\u2C94\u2C96\u2C98\u2C9A\u2C9C\u2C9E\u2CA0\u2CA2\u2CA4\u2CA6\u2CA8\u2CAA\u2CAC\u2CAE\u2CB0\u2CB2\u2CB4\u2CB6\u2CB8\u2CBA\u2CBC\u2CBE\u2CC0\u2CC2\u2CC4\u2CC6\u2CC8\u2CCA\u2CCC\u2CCE\u2CD0\u2CD2\u2CD4\u2CD6\u2CD8\u2CDA\u2CDC\u2CDE\u2CE0\u2CE2\u2CEB\u2CED\u2CF2\uA640\uA642\uA644\uA646\uA648\uA64A\uA64C\uA64E\uA650\uA652\uA654\uA656\uA658\uA65A\uA65C\uA65E\uA660\uA662\uA664\uA666\uA668\uA66A\uA66C\uA680\uA682\uA684\uA686\uA688\uA68A\uA68C\uA68E\uA690\uA692\uA694\uA696\uA698\uA69A\uA722\uA724\uA726\uA728\uA72A\uA72C\uA72E\uA732\uA734\uA736\uA738\uA73A\uA73C\uA73E\uA740\uA742\uA744\uA746\uA748\uA74A\uA74C\uA74E\uA750\uA752\uA754\uA756\uA758\uA75A\uA75C\uA75E\uA760\uA762\uA764\uA766\uA768\uA76A\uA76C\uA76E\uA779\uA77B\uA77D-\uA77E\uA780\uA782\uA784\uA786\uA78B\uA78D\uA790\uA792\uA796\uA798\uA79A\uA79C\uA79E\uA7A0\uA7A2\uA7A4\uA7A6\uA7A8\uA7AA-\uA7AD\uA7B0-\uA7B4\uA7B6\uFF21-\uFF3A]

// Number, Decimal Digit
Nd "unicode number" = [\u0030-\u0039\u0660-\u0669\u06F0-\u06F9\u07C0-\u07C9\u0966-\u096F\u09E6-\u09EF\u0A66-\u0A6F\u0AE6-\u0AEF\u0B66-\u0B6F\u0BE6-\u0BEF\u0C66-\u0C6F\u0CE6-\u0CEF\u0D66-\u0D6F\u0DE6-\u0DEF\u0E50-\u0E59\u0ED0-\u0ED9\u0F20-\u0F29\u1040-\u1049\u1090-\u1099\u17E0-\u17E9\u1810-\u1819\u1946-\u194F\u19D0-\u19D9\u1A80-\u1A89\u1A90-\u1A99\u1B50-\u1B59\u1BB0-\u1BB9\u1C40-\u1C49\u1C50-\u1C59\uA620-\uA629\uA8D0-\uA8D9\uA900-\uA909\uA9D0-\uA9D9\uA9F0-\uA9F9\uAA50-\uAA59\uABF0-\uABF9\uFF10-\uFF19]

Digit "digit" = [0-9]

// Separator, Space
Zs "space" = [\u0020\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000]
