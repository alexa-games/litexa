# Litexa Extensions

Litexa supports custom extensions, which are special Node modules that can be installed to augment
Litexa's core functionality. These extensions can be installed locally in a Litexa project's parent
directory (in which case they only affect that individual project), or globally (in which case they
affect all Litexa projects on the same machine).

Examples of such extensions are the [@litexa/gadgets extension](echo-buttons.html#installation), the
[@litexa/apl extension](screens.html#installation), and the
[@litexa/render-template extension](appendix-render-template.html#installation). These extensions
allow for optional customizations of Litexa, and can be installed on a project-by-project basis,
depending on requirements.

Litexa extensions support the following customizations:

1. extending Litexa's language with new statements
2. adding new validators to Litexa's compilation and testing steps
3. adding new runtime functionality

:::warning Deployment extensions
Extensions modifying Litexa's deployment behavior, such as
[@litexa/deploy-aws](deployment.html#litexa-deploy-aws), currently follow a different structure.
Deployment extensions will be properly documented or assimilated to the below structure, at a
future date.
:::

## Extension Structure

### Extension Specification

For a Node module to be discoverable as a Litexa extension, it must have a `litexa.extension`
specifications file, which can be written in JavaScript (`.js`) or CoffeeScript (`.coffee`):

```bash
myLitexaExtensionDir
├── package.json # Node package name = extension name
├── litexa.extension.js
└── [extension code files]
```

The `litexa.extension` specifications file should export a single **extension initializer** function
which takes 2 parameters, and returns the extension's Litexa customizations:

```js
module.exports = function(options, lib) {
  return {
    language: {
      // Litexa custom syntax definitions
    },
    compiler: {
      // Litexa compilation/testing validators
    },
    runtime: {
      // Litexa runtime handlers
    },
    lib: {
      // Any custom libraries to be merged with Litexa's 'lib' container:
      // These libraries become available during compilation/runtime.
      // Specifying libraries that name clash with existing Litexa core
      // libraries or other extension libraries will throw an error.
    }
  }
}
```

### Extension Initialization

As can be seen in the above `litexa.extension` template, the initializer function is called with
2 parameters, `options` and `lib`. Let's take a closer look at both of these parameters.

1. **options**: These are `extensionOptions` which can be specified in a Litexa project's Litexa
config file. Let's assume we have a Litexa project with the following `litexa.config.js`:

    ```js
    module.exports = {
      "name": { /* ... */ },
      "deployments": { /* ... */ }
      "extensionOptions": {
        "myExtension": { verbose: true }
      }
    }
    ```

    Now, if we had "myExtension" installed in our project (or globally), running this Litexa project
    would initialize "myExtension" with `options = { verbose: true}`. These extension options can be
    leveraged to support custom initialization behavior for individual projects (such as enabling
    verbose logs, in this case).

2. **lib**: This is the container for all of Litexa's shared libraries which are assembled in
`@litexa-core/src/parser/parserlib.coffee`. These libraries can be used, extended, and even modified
by Litexa extensions.

    As a simple example, Litexa's parsing error handler `lib.ParserError(location, errorString)`
    is usable in any extension through this passed `lib` container.

## Extension Customizations

Now, let's take a closer look at the aforementioned 3 types of customizations that are possible
through extensions:

1. extending Litexa's `language`
2. extending Litexa's `compiler`
3. extending Litexa's `runtime`

### 1) Language Extension

The Litexa parser is written in [PEG.js](https://pegjs.org/documentation), which is a simple parser
generator for JavaScript. If unfamiliar, we highly recommend taking a look at the linked
documentation and Litexa's parser file `@litexa/core/src/parser/litexa.pegjs`, before proceeding.

In summary, PEG.js grammar consists of top level *rules* which are made up of a *name* and a
*parsing expression*. The *parsing expression* in turn consists of a *pattern* to match in the
target language, and optionally some JavaScript *handler code* to be executed when the pattern is
successfully matched.

An example of a simple PEG.js rule would be:

```js
integer // name of rule
// start parsing expression
  = digits:[0-9]+ { // pattern to match
    // optional handler code, to be run whenever pattern is matched
    return parseInt(digits.join(""), 10);
  }
// end parsing expression
```

All Litexa rules are listed in the parser file `@litexa-core/src/parser/litexa.pegjs`, which
specifies different categories of Litexa statements. Those modifiable by extensions are the
**StateStatements** (keywords that can be used in
[Litexa state handlers](state-management.html#litexa-states)), and
the **TestStatements** (keywords that can be used in [Litexa tests](testing.html#where-do-i-start)).
An overview of all statements currently supported by Litexa's core package can be found in the
[Language Reference](/reference/).

It is possible for extensions to add new state statements and test statements, by specifying the
following `language` fields in the object returned by the extension initializer:

```js
// litexa.extension.js
module.exports = function(options, lib) {
  return {
    lib: {
      // share our own custom parsing lib with Litexa; details below
      myCommandParser: require('./myCommandParser')(lib)
    },

    language: {
      statements: {
        // "statements" are new keywords we'd like to enable in Litexa code

        myCommand: { // name of the statement to be added

          // now let's add a parser rule with the structure:
          // [rule_name] = [pattern] { [optional JS handler] }
          parser: `myCommand
            = 'myCommand' __ type:QuotedString {
              pushCode(location(), new lib.myCommandParser(type));
            }
            / 'myCommand' {
              pushCode(location(), new lib.myCommandParser());
            }`
          /*
            location() ... specifies where we matched our pattern
            pushCode() ... replaces the matched pattern with our specified output
            new lib.myCommandParser() ... since we exported myCommandParser
              to Litexa through 'lib', we can call it here during parsing
          */
        }
      },
      testStatements: {
        // "testStatements" are new keywords we'd like to enable in Litexa tests

        myTestCommand: { // name of the test statement to be added

          // handler code can also trigger some one-time command during compilation,
          // instead of replacing the keyword with runtime code
          parser: `myTestCommand
            = 'myTestCommand' {
              console.log("Litexa used myTestCommand.");
            }`
        }
      }
    }
  }
}
```

:::tip Leverage existing parsing rules
As seen in the above example of `myCommand`, the pattern checks for an existing Litexa rule
"QuotedString", which would match any String between single or double quotes. Any existing Litexa
parsing rules can be reused in your custom parsing logic, so we highly recommend familiarizing
yourself with the existing rules in `litexa.pegjs` before proceeding to add your own.
:::

#### What should my `pushCode` parser look like?

As can be seen in the above example, we've exported our own parser to Litexa through our
extension `lib` (which will be merged with Litexa's `lib`). This parser function can be
`require`d from a file in our extension's Node package, or we can define it directly within
the `litexa.extension` file.

:::tip Pass Litexa 'lib' to any additional extension files
We recommend passing the Litexa `lib` received in the initializer function on to any other extension
files required from `litexa.extension`, as needed. Doing so will provide visibility of any Litexa
libraries that may be needed.
:::

Now, if we want to call our custom extension parser in a `pushCode()`, it should support a function
(or class constructor) with the following structure:

```js
// myCommandParser.js
module.exports = function(lib) {
  /*
    according to the above tip, we'll dependency inject the Litexa 'lib'
    when requiring this parser

    then, we'll return an initializer function or constructor, to be callable
    by the Litexa parser and accept whichever parameters we expect:
  */
  return function (commandType = undefined) {
    // our example matches newCommand with AND without a "type" -> handle both
    this.attributes = {
      commands: {type: commandType}
    };

    /*
      Required: Our extension must return a toLambda() function. This
      function will be called with the stringified Lambda "output" up
      until our keyword, and allow attaching our own stringified code
      in place of the keyword.
    */
    this.toLambda = function(output, indent, options) {
      // Let's add some data to the Litexa 'context'.
      output.push(`context.myCommandData = "myCommand was used";`);
    }

    /*
      Optional: We can support command "attributes" with a pushAttribute()
      function. Litexa would then push these attributes in case of this syntax:

      myNewCommand
        key: value
    */
    this.pushAttribute = function(location, key, value) {
      if (!isValidKey(key)) {
        // since we dependency injected the Litexa 'lib', we can now use
        // any Litexa library here, such as ParserError
        throw new lib.ParserError(location, `Invalid key.`);
      }
      if (!isValidValue(value)) {
        throw ner lib.ParserError(location, `Invalid value.`);
      }
      // If we were able to validate key and value, we can push them
      // and use them anywhere we need to (e.g. in toLambda()).
      this.attributes.commands[key] = value;
    }

    /*
      Optional: This function can be used to automatically support required
      interfaces. For instance, the @litexa/apl extension adds support for
      the required ALEXA_PRESENTATION_APL interface.
    */
    this.collectRequiredAPIs = function(apis) {
      apis['MY_REQUIRED_INTERFACE'] = true;
    }
  };
}

```

### 2) Compiler Extension

The `compiler` specification can whitelist event types, and add validators for:

1. skill manifest (validated during deployment)
2. skill interaction model (validated during deployment)
3. skill directives (validated during Litexa tests)

Let's take a look at a `compiler` example:

```js
// litexa.extension.js
module.exports = function(options, lib) {
  compiler: {
    manifest: (manifestValidator) { /* ... */ }
    model: (modelValidator) { /* ... */ }
    directives:
      aDirectiveName: (directiveValidator) {/* ... */ }
      anotherDirectiveName: (directiveValidator) { /* ... */ }
  },
  validEventNames: [
    /*
      By default, Litexa accepts the following event types:
        LaunchRequest, IntentRequest, Connections.Response
      Extensions can whitelist additional event types, by adding them to this array.
    */
    'NAMESPACE.NewValidEvent'
  ]
}
```

As seen above, every validator function receives one parameter which is a pre-made JSON validator
object with the following structure:

```js
validator: {
  jsonObject: // this is the manifest, or model, or directive, respectively
  errors: []  // this is an error stack for all validation errors:
              // all errors are printed after validation is complete
}
```

Validators for manifest, model, or directives work similarly. The only difference is that the first
two are called during deployment, while directives are validated during Litexa tests. Here's an
example of supplying a custom directive validator through an extension:

```js
compiler: {
  directives:
    "myCustomDirective": function(validator) {
      // Litexa will pass any "myCustomDirective" to this function, for validation

      const directive = directive.jsonObject;
      const params = [ /* expected parameters */ ]

      // Aside from custom validation, the passed 'validator' object supplies
      // utility functions for validation.

    // 1) error printing for independent validation
      // add custom error message
      validator.errors.push(message);
      // add error that specified key failed validation due to "message":
      validator.fail(key, message);

    // 2) error handling for object values
      // add error if key's value not of type boolean:
      validator.boolean(key);
      // add error unless key's value is an integer between specified bounds:
      validator.integerBounds(key, min, max);
      // add error if key's value not in the provided array of "choices":
      validator.oneOf(key, choices);

    // 3) error handling for object keys
      // add error if any of keys are missing in the jsonObject:
      validator.require(keys);
      // add error if any non-whitelisted keys found in jsonObject:
      validator.whitelist(keys);
      // combined validation of above 'require' + 'whitelist':
      validator.strictOnly(keys);
    }
}
```

### 3) Runtime Extension

The `runtime` specification can add new runtime functionality to Litexa. Let's take a look at what
`runtime` might look like:

```js
// litexa.extension.js
module.exports = function(options, lib) {
  runtime: {
    apiName: "myAPI", // extension namespace: see 'userFacing' below, for application
    source:  require("./myRuntimeHandler.js") // source code for extension handler
  }
}
```

The runtime handler source code should export a single function that will receive the
[Litexa context](backdoor.html#reading-and-modifying-litexa-s-context) as a parameter (we
highly recommend reviewing the documentation on the Litexa context before proceeding).

By using this Litexa `context` object, extension runtime handlers can check incoming request data,
and modify outgoing response data! Such a runtime handler can define the following:

1. `userFacing` variables or methods (callable through the extension `apiName`)
2. `events` handlers: code to be run during certain runtime stages
3. `requests` handlers: code to be run after receiving certain request types

Let's take a closer look at what this might look like:

```js
// myRuntimeHandler.js
module.exports = function(context) {
  const myData = {
    /*
      An extension can track private data outside of the return statement.
      Note, that this data will be re-instantiated for every skill request.

      If absolutely necessary, this data can be persisted between requests
      by writing/reading to the DB with context.db.write/read('_myAPI').
      Persisting extension data in DB storage will increase latency due to
      the required DB operations.
    */
    greeting: "This is a custom greeting."
  }

  return {
    // Extensions can optionally export user facing variables and methods,
    // which become available under the extension's apiName in inline code.
    userFacing: {
      secret: 13,         // invoked with myAPI.secret
      sayHi: function() { // invoked with myAPI.sayHi()
        context.say.push(myData.greeting);
      }
    }

    // Extensions can add the following event-specific handlers:
    events: {
      afterStateMachine: function() {
        // logic to be run after completing all pending state transitions
        // use case example: if the parser modified the context object, such
        // as adding 'context.myCommandData' as seen above, we could check it here
        if (context.myCommandData) {
          context.say.push(context.myCommandData);
        }
      },
      beforeFinalResponse: function(response) {
        // logic to be run before sending the skill response object
        // use case example: we could set a specific a response flag here
        response.flags = response.flags ? response.flags : {};
        response.flags.myCustomFlag = true;
      }
    }

    // Extensions can add request-type-specific handlers, which would
    // be invoked immediately upon receiving the specified requests.
    requests: {
      'SYSTEM.MyExpectedIntent': function (request) {
        console.log("myExtension registered a SYSTEM.MyExpectedIntent request.");
      }
    }
  }
}
```

## Conclusion

The goal of Litexa extensions is to provide the means to adapt Litexa's capabilities for individual
needs. These individual use cases might be very unique to a single user (I want Litexa
to support my custom framework), or more broadly applicable to a larger group (I want Litexa
to directly support Alexa feature XYZ).

We highly encourage writing these plugins, and sharing them with the community in case of
general applicability.
