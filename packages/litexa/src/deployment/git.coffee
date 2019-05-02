child_process = require 'child_process'

execPromise = (command) ->
  new Promise (resolve, reject) ->
    child_process.exec command, {}, (err, stdout, stderr) ->
      if stderr
        return reject("" + stderr)
      if err?
        return reject("" + err)
      resolve(stdout)

exports.getCurrentState = ->
  info = {}

  execPromise 'git rev-parse HEAD'
  .then (data) ->
    info.currentCommitHash = data.trim()
    execPromise 'git log --format=%B  -n 1  HEAD'
  .then (data) ->
    # convert multiline comment into array for readability in a JSON file
    comment = ( l for l in data.trim().split('\n') when l )
    info.currentCommitComment = comment
    execPromise 'git diff --name-status HEAD'
  .then (data) ->
    lines = data.split('\n')
    typeMap =
      D: "deleted"
      M: "modified"
      A: "added"
    lines = for l in lines when l.length > 0
      parts = l.split '\t'
      type = typeMap[parts[0]] ? parts[0]
      "[#{type}] #{parts[1]}"
    info.uncommittedChanges = lines
    Promise.resolve(info)
  .catch (err) ->
    info.currentCommit = "could not retrieve git info"
    info.gitError = "" + err
