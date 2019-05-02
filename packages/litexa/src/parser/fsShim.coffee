module.exports.readFileSync = (filename) ->
  throw "FSSHIM: Missing file #{filename}" unless filename of litexa.files
  return litexa.files[filename]
