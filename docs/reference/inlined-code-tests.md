# Inlined Code Test Reference

This reference contains functionality you can use for your
inlined Litexa code tests. For more information, refer to
the [Testing Chapter](/book/testing.html) of the Book.

If you'd like to look at the source code for this test library, go
to the litexa package's `src/parser/testing.coffee`'s TestLibrary class.

## Test.error(message)

Throws an error with the message specified.

## Test.equal(a, b)

Checks `a==b` and throws an error if it is false.

## Test.check(condition)

Takes in a function `condition` and evaluates it on its
truthiness value (See CoffeeScript truthiness values reference).

## Test.report(message)

Outputs the message specified with a `t!` prepended to it.
The message can be an object.

## Test.warning(message)

Outputs the message specified with a `t✘!` prepended to it.
The message can be an object.

## Test.expect(name, condition)

This specifies an individual test case, with `name` being
the name of your test, and `condition` being the function
that executes the test contents. The name will be the
reference used in your `litexa test` output.

For example, this is a test called "stuff to work":

```javascript
Test.expect("stuff to work", function() {
  Test.equal(typeof (todayName()), 'string');
  Test.check(function() {
    return addNumbers(1, 2, 3) === 6;
  });
  return Test.report(`today is ${todayName()}`);
});
```

## Test.directives(title, directives)

This is equivalent to `directive` in your Litexa tests, but
applicable to your inlined code tests. The title field is
the name of your directive test that will be used in output.
The directive field takes in a directive or an array of
directives. It will perform validation checks against the
input directives and output any violations to the console.
Otherwise, if it passes validation, it will output an "OK".

For example, this is a test with valid syntax, but wouldn't
pass if simply added to a skill:

```javascript
Test.expect("dummy directive testing", function() {
  Test.directives("dummy directive", {type: "dummy"})
});
```