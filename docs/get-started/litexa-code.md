
# Litexa code

*If you want to go straight to trying your new skill out, feel free to [skip this section](building-and-running).
Here we'll skim through the contents the code files we just generated.*


::: tip Syntax Highlighting
If you want to be able to better read the code samples, we provide a Visual Studio Code
extension to support Litexa syntax highlighting.
You can find it under the folder `packages/litexa-vscode` in the Litexa codebase.

For other editors, we recommend extending your `coffeescript` syntax highlighting to include `*.litexa` files,
which is a pretty good approximation of Litexa syntax.

For information on how to install go to [Editor Support](../book/appendix-editor-support.md).
:::

## `main.litexa`

Before we run our code, lets take a look at the contents of our code files in the `litexa` folder.

Open the `main.litexa` file and take a minute to look it over. In it, you should see the following sections
`launch`, `askForName`, `waitForName`, and `goodbye`, each with its own content.
These are the *states* of your skill. The content under each state defines
what your skill should do when it enters, leaves, or receives input while in the state.
Each of these events may move the skill into another state as
part of it's logic, creating a connected graph of states.

It's not expected that you should be able to read and understand this immediately,
but the file should give you a general sense for what you expect this skill to do.
Breaking it down from the viewpoint of Alexa, it should read a little something like this:

```coffeescript
# start with a launch state
launch
  # greet the user, with their name if we have it
  if @name
    say "Hello again, @name.
         Wait a minute... you could be someone else."
  else
    say "Hi there, human."
  # move on to the askForName state
  -> askForName
```
> When I launch, I will greet the user by name if I have it,
> or provide a generic greeting. Either way, I will then immediately
> move on to the `askForName` state.


```coffeescript
askForName
  # add this question to our next response
  say "What's your name?"
  # add an automatic re-prompt, in case the user says nothing
  reprompt "Please tell me your name?"
  -> waitForName
```
> When I arrive at `askForName`, I ask for their name and if I need to reprompt them,
> I'll prepare to say "Please tell me your name?".
> I'll then immediately transition to the `waitForName` state.


```coffeescript
waitForName
  # do nothing when we start this state, and go nowhere; this ends the handler,
  # sends our response, and opens the microphone to listen
```
> When I arrive at the `waitForName` state I'll do nothing, which by default
> means I'll cause the Alexa device's microphone to open, and wait for input.


```coffeescript
  when "my name is $name"
    or "call me $name"
    or "$name"
    with $name = AMAZON.US_FIRST_NAME
    # if user answers with a name from our names list

    # save the name in the permanent database
    @name = $name

    say "Nice to meet you, $name. It's a fine {todayName()}, isn't it?"
    -> goodbye
```
> If I'm in the `waitForName` state, when the user replies with their name,
> I'll save it, say that it's nice to meet them,
> and then immediately transition to the `goodbye` state.


```coffeescript
  when AMAZON.HelpIntent
    # if user says something that maps to the built-in help intent
    say "Just tell me your name please. I'd like to know it."
    reprompt "Please? I'm really curious to know what your name is."
    # loop back to waiting for a name
    -> waitForName
```
> Alternatively, while I'm in the `waitForName` state, when the user asks
> for help, I'll rephrase my request for their name,
> and then immediately transition back to `waitForName`


```coffeescript
  otherwise
    # if user says something that maps to neither of the above intents
    say "Sorry, I didn't understand that."
    # loop back to asking for the name
    -> askForName
```
> While in the `waitForName` state, when any other unexpected input arrives,
> I'll say I didn't understand, and then immediately transition back to `askForName`,
> in order to restart that flow.


```coffeescript
goodbye
  say "Bye now!"
  # we're done with the skill; end the skill session
  END
```
> When I arrive at the `goodbye` state, I say goodbye, and then end the session.


## `main.test.litexa`

Great! Now that we have a sense for what our application should do when we run it, we should have a way to simulate user
interaction with your skill and check what we expected to happen. Open the `main.test.litexa` file, and you'll find a
couple of the scenarios we've described.

Litexa provides you with a quick way to verify and assert that your litexa code behaves the way you'd expect.
Again, it's not expected that you should be able to read this immediately, but the file should give you a general sense
for what we're testing for.

These test scenarios are written from the perspective of someone observing the interaction between the user and Alexa.
Let's take a look at the first chunk:

<<< @/packages/litexa/src/command-line/templates/common/litexa/main.test.litexa{1-6}

When the user launchs the skill, Alexa is expected to end up in the `waitForName` state.
We then simulate the user saying "my name is Dude".
After this, we expect that the skill should have stored the name "Dude" as given.
The session is then expected to have ended.

::: tip Testing
For more information on ensuring your code works properly, check out the cookbook section on [Testing](../book/testing.md).
:::

