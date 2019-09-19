LoggingChannel = require '../loggingChannel'
{ spawn } = require('child_process')

###
# Utility function to call a SMAPI command via the `ask api` CLI.
# @param askProfile ... required ASK profile name
# @param command    ... required ASK API command
# @param params     ... optional flags to send with the command
# @param logChannel ... optional caller's LoggingChannel (derived from for SMAPI logs)
###
module.exports = {
  call: (args) ->
    askProfile = args.askProfile
    command = args.command
    params = args.params
    logger = if args.logChannel then args.logChannel.derive('smapi') else new LoggingChannel({logPrefix: 'smapi'})

    unless command
      throw new Error "SMAPI called without a command. Please provide one."

    cmd = 'ask'
    args = [ 'api', command ]

    unless askProfile
      throw new Error "SMAPI called with command '#{command}' is missing an ASK profile. Please
        make sure you've inserted a valid askProfile in your litexa.config file."

    args.push '--profile'
    args.push askProfile

    for k, v of params
      args.push "--#{k}"
      args.push "#{v}"

    @spawnPromise(cmd, args)
    .then (data) ->
      if data.stdout.toLowerCase().indexOf("command not recognized") >= 0
        throw new Error "SMAPI called with command '#{command}', which was reported as an invalid
          ask-cli command. Please ensure you have the latest version installed and configured
          correctly."

      logger.verbose "SMAPI #{command} stdout: #{data.stdout}"
      logger.verbose "SMAPI stderr: #{data.stderr}"

      if data.stderr and data.stderr.indexOf('ETag') < 0
        throw data.stderr
      Promise.resolve data.stdout
    .catch (err) ->
      if typeof(err) != 'string'
        if err.message and err.message.match /\s*Cannot resolve profile/i
          throw new Error "ASK profile '#{askProfile}' not found. Make sure the profile exists and
            was correctly configured with ask init."
        else
          throw err

      # else, err was a string which means it's the SMAPI call's stderr output
      code = undefined
      message = undefined
      try
        lines = err.split '\n'
        for line in lines
          k = line.split(':')[0] ? ''
          v = (line.replace k, '')[1..].trim()
          k = k.trim()

          if k.toLowerCase().indexOf('error code') == 0
            code = parseInt v
          else if k == '"message"'
            message = v.trim()
      catch err
        logger.error "failed to extract failure code and message from SMAPI call"

      unless message
        message = "Unknown SMAPI error during command '#{command}': #{err}"

      Promise.reject { code, message }

  spawnPromise: (cmd, args) ->
    return new Promise (resolve, reject) =>
      spawnedProcess = spawn(cmd, args, {shell:true})

      stdout = ''
      stderr = ''

      spawnedProcess.on('error', (err) ->
        if err.code == 'ENOENT'
          throw new Error "Unable to run 'ask'. Is the ask-cli installed and configured
            correctly?"
        else
          throw err
      )
      spawnedProcess.stdout.on('data', (data) ->
        stdout += data
      )
      spawnedProcess.stderr.on('data', (data) ->
        stderr += data
      )

      resolver = ->
        resolve {
          stdout,
          stderr
        }

      spawnedProcess.on('exit', resolver)
      spawnedProcess.on('close', resolver)
}
