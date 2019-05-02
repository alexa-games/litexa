Test.expect("stuff to work", function () {
  console.log(RuntimeInline.hello());
  if (RuntimeInline.secret != 13) {
    throw new Error("wrong secret for RuntimeInline");
  }

  console.log(RuntimeRequire.hello());
  if (RuntimeRequire.secret != 7) {
    throw new Error("wrong secret for RuntimeRequire");
  }
});
