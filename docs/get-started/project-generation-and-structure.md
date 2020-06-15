# The litexa project

A litexa project is a tree of files that together describe a single Alexa skill. Much of litexa
relies on finding the right files in the right locations, which the generator can help set up.


## Generating a litexa project

Once you've installed the Litexa CLI you can create a new Litexa project by opening up a terminal, navigating to
a directory where you have rights to create files, and typing:

```bash
litexa generate
```

At this point you'll get a series of questions to help you get started. For now, answer the questions with the following
options:

<pre style="padding:0">
  <code>
    <span style="color:green">?</span> In which directory would you like to generate your project? <span style="color:#00caff">hello-litexa</span>
    <span style="color:green">?</span> Which language do you want to write your code in? <span style="color:#00caff">JavaScript</span>
    <span style="color:green">?</span> How would you like to organize your code? <span style="color:#00caff">Inlined in litexa</span>
    <span style="color:green">?</span> what would you like to name the project? <span style="color:#00caff">hello-litexa</span>
    <span style="color:green">?</span> what would you like the skill store title of the project to be? <span style="color:#00caff">hello-litexa</span>
  </code>
</pre>

This one command will create a new directory called `hello-litexa` and set up a simple Litexa project inside of it.
It will also print out the file names of the files it generated to the console.




## The litexa project structure

Let's review in a little more depth what files were generated and what our application looks like.

```bash
cd hello-litexa
```

If we take a look at the contents of the directory we notice they look something like this

```bash
.
├── README.md
├── artifacts.json
├── litexa
│   ├── assets
│   │   ├── icon-108.png
│   │   └── icon-512.png
│   ├── main.litexa
│   ├── main.test.litexa
│   ├── utils.js
│   └── utils.test.js
├── litexa.config.js
└── skill.js
```

::: tip Documentation
The **README.md** is a great place to start after generating a project. It provides information specific to the type of project
you've generated, and also includes a succinct synopsis of the contents covered in this getting started guide.
:::

This directory contains an number of auto-generated files and folders that make up the structure of a basic
litexa project. Here's a short rundown of each of the files and folders created by default:

* `README.md` contains useful tidbits of knowledge pertaining to your generated project.
* `artifacts.json` file stores generated information about the project.
* `litexa.config.js` is your project configuration file.
* `skill.js` is a representation of your skill that provides required metadata to Alexa.
* `litexa` folder houses your assets, litexa files, and skill logic:
  * `assets` contains any images, videos and sounds you'd like to deploy with your project.
  * `*.litexa` files are the Litexa language files.
  * `*.js` files are code files. Anything defined in them will be visible in the litexa global scope.

::: warning Importing Code
As mentioned above, code files inside of the `litexa` directory are treated differently.

For example, variable declarations and function definitions in a JavaScript file will be globally scoped. **This means
`require` and `import` have limited support in this context**. If you wish to organize your code in a way that you can
import/require your own files, you can run `litexa generate` and select the `As modules.` or `As an application.` option.

For more information on this and for generation shorthands, check out the [Project Structure](../book/project-structure.md)
section of the cookbook.
:::