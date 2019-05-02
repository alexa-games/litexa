# Appendix: Display Render Template

::: tip
For some background information on using screens in Alexa skills, please refer to [Screens](/book/screens.html).
:::

Alexa's `Display` interface allows for showing static, one-size-fits-all templates on compatible
Alexa-enabled screen devices. Using such `render templates`, it is possible to:

* display one of five body templates (different layouts of text and images)
* display one of two list templates (vertical/horizontal scrollable list items)
* use HTML tags for text formatting of certain text fields

## Display Render Template Directive

Every Alexa response can include one render template in a
[Display.RenderTemplate](https://developer.amazon.com/docs/custom-skills/display-interface-reference.html#form-of-the-displayrendertemplate-directive)
directive. As mentioned above, the render template can be one of seven, as detailed here:
[Display Template Reference](https://developer.amazon.com/docs/custom-skills/display-template-reference.html)

The module `@litexa/render-template` supports easily building, sending, and validating a `Display.RenderTemplate`
directive. Please find the information on how to install and use this module below.

:::tip
When installed, `@litexa/render-template` will validate any `Display.RenderTemplate` directive added to a response,
even if the directive wasn't built using the module's `screen` statement.
:::

## Installation

The module can be installed globally, which makes it available to any of your Litexa projects:

```bash
npm install -g @litexa/render-template
```

If you alternatively prefer installing the extension locally inside your Litexa project, for the sake of tracking the
dependency, just run the following inside of your Litexa project directory:

```bash
npm install --save @litexa/render-template
```

This should result in the following directory structure:

```stdout
project_dir
├── litexa
└── node_modules
    └── @litexa
        └── render-template
```

## New Statement

When installed, the module adds a new `screen` statement to Litexa's syntax, which can be used to send a
specific render template type via directive as follows:

```coffeescript
screen
  template: "BodyTemplate1"
```

The supported template types are split into two categories:

### 1) Body Templates

The following body templates are supported along with their respective attributes:

| template type |`background`|`title` |`primaryText`|`secondaryText`|`tertiaryText`|`displaySpeechAs`|`image` |`hint`  |
|---------------|:----------:|:------:|:-----------:|:-------------:|:------------:|:---------------:|:------:|:------:|
| BodyTemplate1 | &#10003;   |&#10003;|&#10003;     |&#10003;       |&#10003;      |&#10003;         |        |        |
| BodyTemplate2 | &#10003;   |&#10003;|&#10003;     |&#10003;       |&#10003;      |&#10003;         |&#10003;|&#10003;|
| BodyTemplate3 | &#10003;   |&#10003;|&#10003;     |&#10003;       |&#10003;      |&#10003;         |&#10003;|        |
| BodyTemplate6 | &#10003;   |&#10003;|&#10003;     |&#10003;       |&#10003;      |&#10003;         |        |&#10003;|
| BodyTemplate7 | &#10003;   |&#10003;|             |               |              |&#10003;         |&#10003;|        |

#### Example: BodyTemplate2

Here's an example of sending a `BodyTemplate2` with every possible attribute (any subset of attributes is allowed).

```coffeescript
screen
    template: BodyTemplate2
    title: "Cheese Varieties"
    primaryText: "Brie originated in France"
    secondaryText: "Gruyere originated in Switzerland"
    tertiaryText: "Gorgonzola originated in Italy"
    background: background.jpg
    image: "https://www.example.com/my-image.png"
    displaySpeechAs: "title"
    hint: "Cheesy Hint"
```

::: tip displaySpeechAs
This attribute requires a value that is:

* one of `[title, primaryText, secondaryText, tertiaryText]`
* supported by the specified template type

Setting this attribute will:

1. concatenate any output speech sent in the next response to the indicated text field
2. strip any SSML tags (e.g. `<say-as interpret-as='ordinal'>`) from the displayed text
:::

### 2) List Templates

The following list templates are supported along with their respective attributes:

| template type |`background`|`title` |`list`  |
|---------------|:----------:|:------:|:------:|
| ListTemplate1 | &#10003;   |&#10003;|&#10003;|
| ListTemplate2 | &#10003;   |&#10003;|&#10003;|

::: tip list
This attribute requires an `array` of list items. Each list item is an `object` with
any subset of the attributes: `[token, primaryText, secondaryText, tertiaryText, image]`
:::

::: tip token
This new `list` item-specific attribute is optional, and can be used to set a `String` identifier for the associated
list item. For example:

```javascript
// list item:
{
  token: "My List Item's Token",
  primaryText: "My List Item's Text"
}
```

The specified token can then be used to allocate a touch event to the list item, as seen in the following example.
:::

#### Example: ListTemplate1

Here's an example of sending a `ListTemplate1` with every attribute, and handling touch events.

Dynamically generating the list in some JS code:

```javascript
// static list
let list = [
    {token: 'brie', primaryText: 'Brie (France)', image: 'brie.jpg'},
    {token: 'gruyere', tertiaryText: 'Gruyere (Switzerland)', image: 'gruyere.jpg'},
];

// alternative or supplementary code to assemble/manipulate a dynamic list
let listItem = {token: 'gorgonzola', primaryText: 'Gorgonzola (Italy)', image: 'gorgonzola.jpg'};
list.push(listItem);
// (...)

const getList = function() {
    return list;
}
```

Sending the list directive in litexa:

```coffeescript
local myCheeseList = getList()
screen
    template: ListTemplate1
    background: background.jpg
    title: "Cheese List"
    list: myCheeseList

when Display.ElementSelected
    say "You touched list item {$request.token}."
```

The above example would display the defined `list` on the screen and, if an item were touched by the user,
Alexa would say the item's token out loud. The touch event and corresponding token can be handled in
whichever way is required.

## Statement Shorthands

There are several statement shorthand options available.

```coffeescript
screen [title] [background]  # screen "My Title" background.jpg
screen [background] [title]  # screen background.jpg "My Title"
screen [title]               # screen "My Title"
screen [background]          # screen background.jpg
```

## Statement Attribute Specifications

#### Attribute properties

* If no `template` is specified, the template type defaults to `BodyTemplate1`.
* `hint` will generate a
[Hint Directive](https://developer.amazon.com/docs/custom-skills/display-interface-reference.html#hint-directive)
with the supplied String, and add it to the pending response.
* `image` and `background` expect one of the following:
  * Unquoted or quoted name of a file provided in `litexa/assets`.
  * Existing image's URL as a String (`litexa` does not validate URL's existence).
  * A variable storing either of the above.
* `image` and `primary|secondary|tertiaryText` size and placement depend on which template is used (see examples in
[Display Template Reference](https://developer.amazon.com/docs/custom-skills/display-template-reference.html)).

::: tip
It is useful to frequently test your skill on an Alexa device or the
[ASK Developer Console](https://developer.amazon.com/alexa/console/ask) (ideally test each device type), to detect any
unforeseen rendering issues (e.g. text overflow).
:::

#### Attribute shorthands

As can be seen in the above examples, we've shortened some of the official render template attributes (see
[Display Template Reference](https://developer.amazon.com/docs/custom-skills/display-interface-reference.html)), for
the sake of convenience:

* Use `background` instead of `backgroundImage`.
* Use `list` instead of `listItems`.
* Use `primary|secondary|tertiaryText` instead of a
[textContent](https://developer.amazon.com/docs/custom-skills/display-interface-reference.html#textcontent-object-specifications)
container.

## Text Formatting

The text attributes `primary|secondary|tertiaryText` support the below `RichText` HTML tags.

::: tip NOTE
These HTML tags are supported without requiring closing tags - see the examples below.
:::

### Bold, Italics, Underlined

```coffeescript
"<b a bold sentence 1>"
"<b> a bold sentence 2"
"<b> bold
  not bold"
```

For italics and underlined, use `<i>` and `<u>` analogously.

### Font Sizes

```coffeescript
"<f2 this has font size two> <f3 this has font size three>"
"<f3> font size three"
"regular size <f5 size 5>"
"<f7 size 7> regular size"
```

::: warning
Only the following font sizes are allowed: `[2,3,5,7]`
:::

### Alignment

```coffeescript
"<center something 1>"
"<center>something 2"
"<center> centered
  not centered"
"<center> centered
  <center> also centered"
```

### Mixing Tags

```coffeescript
"<center><u><b>centered, underlined and bold"
"<center><b>centered and bold
  neither
  <b><f7 bold and large><f2 bold and small>"
```

### Special Characters

You should only use the special characters newline (`\n`) and ampersand (`&`) in `primary|secondary|tertiaryText`.
These two characters will automatically be converted to the HTML tags `<br/>` and `&amp;`.

## Intent Handling Requirements

When using a `Render Template` directive, certain built-in intents must be supported by the skill (i.e. included in at
least one `when` listener). Not doing so will result in an error during deployment.

The following intents should be handled correctly by the skill author, to control the skill's screen flow:

```coffeescript
AMAZON.NextIntent
AMAZON.PreviousIntent
```

::: tip EXAMPLE

```coffeescript
when AMAZON.NextIntent
  screen "My Next Screen"
when AMAZON.PreviousIntent
  screen "My Previous Screen"
```

:::

The following intents must also be included, but can be routed to do nothing since they have automatic handling:

```coffeescript
AMAZON.ScrollUpIntent
AMAZON.ScrollDownIntent
AMAZON.ScrollLeftIntent
AMAZON.ScrollRightIntent
AMAZON.MoreIntent
AMAZON.NavigateHomeIntent
AMAZON.NavigateSettingsIntent
AMAZON.PageDownIntent
AMAZON.PageUpIntent
```

::: tip
Examples of the above mentioned automatic handling are:

* ListTemplate1 will automatically "scroll down" and "scroll up"
* ListTemplate2 will automatically "scroll right" and "scroll left"

If no custom handling is required, the intent listeners can be added to an unreachable
[state](/book/state-management.html#litexa-states):

```coffeescript
invalidIntents # nothing points to this state
  when AMAZON.ScrollUpIntent
    # do nothing
```

Doing so will include the intents in the skill model, while not ever actively handling them.

:::

## Checking Render Template Support

To check whether the `Display` interface, and therewith render templates are supported by the active device at runtime,
the following command can be used in `litexa` or external code:

```javascript
RenderTemplate.isEnabled()
```

::: tip
This check can and should be used to potentially compensate for any missing visuals on a voice-only device.
For example:

```coffeescript
  if RenderTemplate.isEnabled()
    screen instructions.png
    say "Please read the instructions on the screen."
  else
    say "Here are your instructions: @instructions"
```

:::

## Relevant Resources

For more information, please refer to the official `Display Render Templates` documentation:

* [Display Interface Reference](https://developer.amazon.com/docs/custom-skills/display-interface-reference.html)
* [Display Render Templates](https://developer.amazon.com/docs/custom-skills/display-template-reference.html)
