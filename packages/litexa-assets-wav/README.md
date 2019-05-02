# Litexa WAV Asset Converter

This module performs automatic
conversion of your WAV asset files to Alexa-compatible MP3
files upon deployment.

Alexa skills require all audio asset files to follow [this
format](https://developer.amazon.com/docs/custom-skills/speech-synthesis-markup-language-ssml-reference.html#h3_converting_mp3).
If your skill will involve heavy or continuous
audio production and assets, the `@litexa/assets-wav`
extension module may be worth installing in your Litexa
project.

## Installation

You will first need to install
[node gyp](https://www.npmjs.com/package/node-gyp). This
supports native add-on modules for Node.js, which is
required because `@litexa/assets-wav` depends on the
[lame](https://www.npmjs.com/package/lame) module.

```bash
npm install -g node-gyp
```

Next, the extension can be installed locally with the
following command:

```bash
npm install @litexa/assets-wav
```

You can choose to install the extension globally instead, by running:

```bash
npm install -g @litexa/assets-wav
```

Doing so, however, will automatically convert all WAV files
to MP3 files in *all* Litexa projects upon deployment. We do
not recommend globally installing this conversion if you plan
to use other asset converters in your projects because it may
produce conflicting or indeterminate output.

If you want to track the extension as a dependency, just run
the following inside of your Litexa project's root directory:

```bash
npm install --save-dev @litexa/assets-wav
```

This should result in the following directory structure:

```stdout
project_dir
├── litexa
└── node_modules
    └── @litexa
        └── assets-wav
```

## Usage

### Automatic conversion (default)

Put your WAV files in the assets folder, in the same way
you would with all other skill assets.

In your Litexa code, refer to the above sound files as if
the MP3-converted version existed in your skill. For
example, if you had introMusic.wav and meow.wav:

```coffeescript
launch
  soundEffect introMusic.mp3
  say "Welcome to the Ultimate Cat Show. <sfx meow.mp3>"
```

### Manual conversion (optional)

For debugging purposes, you can perform an explicit conversion of a
WAV file to the Alexa-supported MP3 by using the conversion
script `convert.coffee` located in the package directly.

Using the script requires you to have
[CoffeeScript](https://coffeescript.org/) installed. You can
install CoffeeScript with the command:

```bash
npm install -g coffeescript
```

Then, you can use its command line to execute the script. For
example:

```bash
coffee convert.coffee meow.wav ./testAssets/meow.mp3
```

The first argument is the path to the WAV file you want to
convert. The second argument is optional and specifies a
destination path for the converted MP3 file. If omitted,
it defaults to the same location as the WAV file path.

If you have a WAV file and MP3 file of the same name in your
assets directory, this extension will halt deployment because it
would produce a duplicate MP3 file. We recommend only using the
script to test what your audio files would sound like after the
conversion, and let the extension handle the conversion
automatically during skill deployment.

## What happens on deployment

Upon deployment, Litexa will automatically convert any WAV
files in the assets folder and locally store the conversion
in `.deploy/converted-assets`. It will also create a hash
file alongside the converted file for caching purposes - it
does not convert files when they haven't changed since the
last deployment.

If you are using the `@litexa/deploy-aws` module for
deployment, it will deploy them to your assets S3 bucket,
following the same steps of non-converted assets. See the
Deployment section of the Book for details.