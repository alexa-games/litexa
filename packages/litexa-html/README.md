# Litexa HTML Support

This module adds support for the Alexa Web API for Games.

The Alexa Web API for Games allows you to use existing web technologies and tools to create 
visually rich and interactive voice-controlled game experiences. You'll be able to build 
for multimodal devices using HTML and web technologies like Canvas 2D, WebAudio, WebGL, 
JavaScript, and CSS, starting with Echo Show devices and Fire TVs.

**NOTE**: The Alexa Web API for Games is currently in Developer Preview. To gain access
to its features & documentation, visit the [Alexa Developer
Blog](https://developer.amazon.com/en-US/blogs/alexa/alexa-skills-kit/2019/11/apply-for-the-alexa-web-api-for-games-developer-preview)
for sign-up information.

## Installation

**WARNING**: The use of this extension is currently reserved for those in the 
Alexa Web API for Games Developer Preview. If you are not in the Developer Preview 
and you have this extension installed, you will not be able to deploy your Alexa 
skills through Litexa.

The module can be installed globally, which makes it available to any of your 
Litexa projects:

```bash
npm install -g @litexa/html
```

If you alternatively prefer installing the extension locally inside your Litexa project, 
for the sake of tracking the dependency, just run the following inside of your Litexa 
project directory:

```bash
npm install --save @litexa/html
```

This should result in the following directory structure:

```stdout
project_dir
├── litexa
└── node_modules
    └── @litexa
        └── html
```

## Adding 'mark' SSML Tags

In your `.litexa` files, you can add `mark` SSML tags to your speech, like so:

```coffeescript
launch
  say "Hello, World!"
  HTML.mark("screen:blue")
  END
```

This will add a substring like `<mark name="screen:blue"/>` to your response's speech. 
This is useful for your HTML runtime in that, when it receives the Alexa response,
the marks can be used to trigger HTML events that interleave with SSML playback.

## Relevant Resources

For more information, please refer to the official Alexa Web API for Games documentation:

* [Alexa Web API 
for Games Announcement](https://developer.amazon.com/en-US/blogs/alexa/alexa-skills-kit/2019/11/apply-for-the-alexa-web-api-for-games-developer-preview)

