module.exports = {
  statement: (context, number) => {
    context.say.push(`Require statement said ${number}.`);
    console.log(`require statement value: ${number}`);
  }
}
