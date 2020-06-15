# Running the skill

You already have a functional Litexa project at this point. To compile and and execute your code, run

```bash
litexa test
```

This command will build and run your Litexa project against your Litexa tests.
You should see the following output:

```coffeescript
2019-3-12 18:03:05 running tests in /Users/You/Documents/Sandbox/template_generation/hello-litexa with no filter
test step 1/3 +0ms: happy path
test step 2/3 +73ms: asking for help
test step 3/3 +11ms: utils.test.js
test steps complete 3/3 87ms total

2019-3-12 18:03:08
✔ 3 tests run, all passed (87ms)

Testing in region en-US, language default out of ["default"]
✔ test: happy path
2.  ❢    LaunchRequest    @ 15:01:05
     ◖----------------◗ "Hi there, human. What's your name?" ... "Please tell me your name?"
4.  ❢   MY_NAME_IS_NAME  $name=Dude @ 15:02:10
     ◖----------------◗ "Nice to meet you, Dude. It's a fine Tuesday, isn't it? Bye now!" ... NO REPROMPT
  ◣  Voice session ended
8.  ❢    LaunchRequest    @ 15:03:15
     ◖----------------◗ "Hello again, Dude. Wait a minute... you could be someone else. What's your name?" ... "Please tell me your name?"
10.  ❢   MY_NAME_IS_NAME  $name=Rose @ 15:04:20
     ◖----------------◗ "Nice to meet you, Rose. It's a fine Tuesday, isn't it? Bye now!" ... NO REPROMPT
  ◣  Voice session ended


✔ test: asking for help
16.  ❢    LaunchRequest    @ 15:01:05
     ◖----------------◗ "Hi there, human. What's your name?" ... "Please tell me your name?"
18.  ❢  AMAZON.HelpIntent  @ 15:02:10
     ◖----------------◗ "Just tell me your name please. I'd like to know it." ... "Please? I'm really curious to know what your name is."
20.  ❢   MY_NAME_IS_NAME  $name=Jimbo @ 15:03:15
     ◖----------------◗ "Nice to meet you, Jimbo. It's a fine Tuesday, isn't it? Bye now!" ... NO REPROMPT
  ◣  Voice session ended


✔ utils.test.js, 1 tests passed
  ✔ utils.test.js 'stuff to work'
  c! the arguments are
  c! {"0":1,"1":2,"2":3}
  t! today is Tuesday

✔ 3 tests run, all passed (87ms)
```

Congrats! You've built, run, and tested your code and you know it's working.

::: tip Modifying the code
Try playing around with the output and the expectations, don't worry about breaking your code. You can always re-generate
another project. In fact, try and break your tests! What happens if you don't save the name?
:::
