# Litexa Projects

A Litexa project is any directory with a valid `litexa.config.json/js/ts/coffee` file in it. 
This directory is called the project root.

Other files that are likely to exist at the project root:
* `artifacts.json`. This file stores generated information about the project, 
  such as the skill ID for each deployment or the ARN of lambdas. You must 
  source control this file to share this information with anyone who works
  on the project.
* `skill.json/js/ts/coffee`. This is a subset of the info found in an Alexa 
  Skill manifest, edited with the assumption that the rest of the information
  will be derived from your project's usage.
* `tsconfig.json` and `tslint.json`. These files exist if you use TypeScript 
  to configure your project. They contain your project configuration's compilation 
  and linting settings.
* `webpack.config.js`. This file exists if you use a webpack bundling-strategy and contains 
  the webpack configuration for the language you chose for your project.
* Language and Project support files. These files will vary based on your bundling-strategy 
  and source-code choice. They tend to be files such as runtime configuration, linting, and
  options for supporting tools.

Under the project root, you can expect to see a number of directories.

One set of directories is ephemeral, it is always safe to delete these 
directories, and you should not version control them:
* `.deploy` is created automatically when you run the command
  `litexa deploy` and contains all the artifacts produced while deploying, 
  and logs that record what happened.
* `.test` is created when you run the command `litexa test` and contains
  all of the artifacts produced while testing.

The main directory of interest under the root is the `litexa` directory. This
contains your Litexa code files, and various other files to support 
them.

Litexa, by default, chooses JavaScript as your source-code, JSON as your configuration, and an inlined 
code organization strategy as your bundling-strategy (more on this later).

## Supported Languages

Litexa currently supports the following languages for Litexa and skill configuration:

* JSON
* JavaScript
* TypeScript
* CoffeeScript

and the following languages for source code generation:

* JavaScript
* TypeScript
* CoffeeScript

## Code Organization Strategies

Litexa has support for three code organization strategies: inlined, separate, and bundling.

### The Inlined Strategy 

This strategy is useful when you are new to Litexa, prototyping, or working on a skill with
limited scope. When you choose this strategy, it generates a single `litexa` folder and configuration 
files at the root of the project.

An example of a generated project might look like this:

```
├── litexa
│   ├── assets
│   │   ├── icon-108.png
│   │   └── icon-512.png
│   ├── languages/
│   ├── main.litexa
│   ├── main.test.litexa
│   ├── utils.js
│   └── utils.test.js
├── litexa.config.json
└── skill.json
```

#### The `litexa` folder

In this folder you may see:
* One or more files with the `.litexa` extension. You write these in the Literate 
  Alexa language.
* One or more files with the extensions `coffee`/`js`/`ts`. These are code 
  files that get inlined with your Litexa handler. Any functions or variables 
  you define here are visible within the states defined in your `.litexa` files.
* An `assets` folder. This contains any images, videos or sounds you'd like to 
  deploy automatically with your project.
* A `languages` folder. This contains a folder per additional language you'd 
  like to support, beyond your default language.
* A `package.json` file. This is a standard npm file and is necessary when you
  have npm packages you would like to depend on and deploy with your skill.
* A `node_modules` file. This contains all of the packages you installed with 
  npm as specified in the `packages.json` file, and will be deployed as a copy 
  along with your handler.
* A `tsconfig.json` and `tslint.json`. These files will exist if you chose TypeScript 
  as the source-code language for your project. They will contain your project 
  configuration's compilation and linting settings for your code.
  
#### Using external packages

To add an external package dependency to your skill, you can run `npm init`
then `npm install` in the `litexa` directory as usual, which will result 
in a `package.json` that describes your skill's dependencies.

You can then require the external packages from any of your inline code 
files, and appropriately import their contents into the Litexa scope.

The entire contents of `litexa/node_modules` will then be copied by the 
Litexa deployment process alongside your skill handler.

To add tools for use during the development of your skill, you can also 
setup a `package.json` file in the project root and install modules as usual.

Some Litexa extension packages that extend functionality during 
compilation, testing or deployment are also designed to be installed at 
the root level, as they do not provide any runtime functionality that needs 
to be copied to the deployed handler. Consult each package's readme for 
details.
  
### The Separate Strategy

This strategy is useful when your use-case requires a decent amount of code logic outside
the Litexa files, your code takes on several external dependencies, and you prefer to organize
your code as local dependencies imported by Litexa. In this context, your local dependency 
is an npm package linked to the `litexa` folder using npm.

The strategy generates two top level directories, a `litexa` folder and a second `lib` directory 
with the supporting code files. The configuration files will be generated at the root of the project.

An example of a generated project might look like this:

```
├── lib
│   ├── index.coffee
│   ├── logger.coffee
│   ├── mocha.opts
│   ├── package.json
│   ├── utils.coffee
│   └── utils.spec.coffee
├── litexa
│   ├── assets
│   │   ├── icon-108.png
│   │   └── icon-512.png
│   ├── main.coffee
│   ├── main.litexa
│   ├── main.test.litexa
│   └── package.json
├── litexa.config.coffee
└── skill.coffee
```

#### The `lib` folder

This folder houses your code. In here you may see:
* One or more code files with the extensions `coffee`/`js`/`ts` and supporting files
  for the source code language. These are scaffolded code files to get you started.
* A `package.json` file. This is the standard npm file for your code and is 
  necessary in order to link your code as an external dependency to Litexa.
  This file will also contain convenient shorthands for compiling your code and other 
  useful operations.
* An `index.js/ts/coffee` file. This is the code entry-point for your dependency.
  Export functions and objects here that you want available for use in Litexa.
  You have to import the dependency in the `litexa` folder to use them in your `.litexa` files.
  An example of this exists in the `main.js/ts/coffee` of your `litexa` folder. 
  Additionally, in the case of TypeScript, your entry-point will be compiled by the TypeScript
  compiler and outputted into `dist/main.js` inside the `lib` folder.


Remember, this folder is a separately managed dependency. Thus, you are free to structure 
your code in anyway you see fit as long as it is a valid npm package that npm can install 
in the `litexa` folder. You can also extend and replicate this pattern by creating new top 
level directories that are local npm packages that you also import into Litexa.

### The Bundling Strategy

This strategy is useful when your use-case requires a minimal deployment, the project's scope 
is a decent size, and you prefer to organize your code as a single application. In this case, 
your application code is bundled into a stand-alone executable that is placed into your `litexa`
folder and the exported objects and functions are visible within the states defined in your `.litexa` files.

This strategy generates three top level directories, a `litexa` folder, a second `lib` folder 
with a directory structure intended to help you organize your code, and a third `test` folder 
that matches the directory structure in the `lib` folder and houses all your tests. 
Additionally, the configuration files will be generated at the root of the project.

An example of a generated project might look like this:

```
├── lib
│   ├── components
│   │   ├── logger.ts
│   │   └── utils.ts
│   ├── index.ts
│   ├── pino-pretty.d.ts
│   └── services
│       └── time.service.ts
├── globals.d.ts
├── litexa
│   ├── assets
│   │   ├── icon-108.png
│   │   └── icon-512.png
│   ├── main.litexa
│   └── main.test.litexa
├── mocha.opts
├── package.json
├── litexa.config.js
├── litexa.config.ts
├── skill.ts
├── test
│   ├── components
│   │   └── utils.spec.ts
│   └── services
│       └── time.service.spec.ts
├── tsconfig.json
├── tslint.json
└── webpack.config.js
```

#### The `lib` and `test` folder

##### Overview

Litexa bundling strategy is fulfilled by webpack. It bundles the contents of `lib` and generates
a single executable, `main.min.js`. Whenever you compile your code, webpack creates that executable
and puts it in the `litexa` folder. Your exported functions and objects are then available to for use
in Litexa within the states defined in your `.litexa` files.

##### Directory Structure and Files
The directory structure of your application looks like this:

```
/litexa       -- Contains Litexa specific files
/lib          -- Root folder for application being developed
  /services   -- Location for service layer calls / data access calls
  /components -- Location for misc business logic ordered by components
/test         -- Test root folder for the application being developer
  /services   -- Location for service layer calls / data access calls tests
  /components -- Location for misc business logic ordered by components tests
```

* In the `lib` root folder contains an `index.js/ts/coffee`.
  This file is a webpack entry-point for your application. Whatever you export in this
  file will be visible and accessible in Litexa through the compiled `main.min.js`.
* The `lib/components` folder contains simple components to help you get started.
  The strategy intends that you use this folder to organize your code by components. Put your 
  components code here.
* The `lib/services` folder contains a simple `time.service.js/ts/coffee` to get 
  you started. The strategy intends that you use this folder to organize your service layer 
  files or data access calls while keeping them separated from your components. Place your 
  service layer or data access code here.
* The `test` folder mimics the directory structure of the `lib` folder. This is where the
  tests will be stored. They have been labeled with the extension `.spec.js/ts/coffee` so they 
  are congruent with TDD file-naming nomenclature.
* The `test/components` folder contains specs for corresponding components.
* The `test/services` folder contains specs for corresponding services.

##### Testing

The strategy configures the generated tests to work with Mocha, Chai, and Sinon in order to
to help you get started the quickest. The mocha options file, `mocha.opts`, is at the root of 
the project and the utility scripts are in `package.json` prefixed with `"test"`.
If you already have a preferred testing stack, please modify this setup-up to suit your needs.
