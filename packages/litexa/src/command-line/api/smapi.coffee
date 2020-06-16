LoggingChannel = require '../loggingChannel'
{ spawn } = require('child_process')

###
# Utility function to call a SMAPI command via the `ask api` CLI.
# @param askProfile ... required ASK profile name
# @param command    ... required ASK API command
# @param params     ... optional flags to send with the command
# @param logChannel ... optional caller's LoggingChannel (derived from for SMAPI logs)
###

# only need to fetch once per session

version =
  major: null
  minor: null
  patch: null


module.exports = {

  version: version

  prepare: (logger) ->
    module.exports.getVersion logger

  getVersion: (logger) ->
    if version.major != null
      return Promise.resolve version

    cmd = 'ask'
    args = [ '--version' ]
    @spawnPromise(cmd, args)
    .then (data) ->
      parts = data.stdout.split '.'
      version.major = parseInt parts[0] ? "0"
      version.minor = parseInt parts[1] ? "0"
      version.patch = parseInt parts[2] ? "0"
      logger.log "ask-cli version #{version.major}.#{version.minor}.#{version.patch}"
      return version


  call: (args) ->
    askProfile = args.askProfile
    command = args.command
    params = args.params
    logger = if args.logChannel then args.logChannel.derive('smapi') else new LoggingChannel({logPrefix: 'smapi'})

    unless command
      throw new Error "SMAPI called without a command. Please provide one."

    if version.major == null
      await @getVersion logger

    cmd = 'ask'
    args = []

    if version.major < 2
      args.push 'api'
      args.push command
    else
      args.push 'smapi'
      args.push command

    unless askProfile
      throw new Error "SMAPI called with command '#{command}' is missing an ASK profile. Please
        make sure you've inserted a valid askProfile in your litexa.config file."

    args.push '--profile'
    args.push askProfile

    for k, v of params
      args.push "--#{k}"
      args.push "#{v}"

    logger.verbose "ask #{args.join ' '}"

    @spawnPromise(cmd, args)
    .then (data) ->
      badCommand = data.stdout.toLowerCase().indexOf("command not recognized") >= 0
      badCommand = badCommand || data.stderr.toLowerCase().indexOf("command not recognized") >= 0
      if badCommand
        throw new Error "SMAPI called with command '#{command}', which was reported as an invalid
          ask-cli command. Please ensure you have the latest version installed and configured
          correctly."

      logger.verbose "SMAPI #{command} stdout: #{data.stdout}"
      logger.verbose "SMAPI stderr: #{data.stderr}"

      if version.major >= 2
        responseKey = "\nResponse:\n"
        responsePos = data.stdout.indexOf responseKey
        if responsePos >= 0
          responsePos += responseKey.length
          response = JSON.parse( data.stdout[responsePos...] )
          logger.verbose "SMAPI statusCode #{response.statusCode}"
          data.stdout = JSON.stringify response.body, null, 2

      if data.stderr and data.stderr.indexOf('ETag') < 0
        throw data.stderr
      Promise.resolve data.stdout
    .catch (err) ->
      if typeof(err) != 'string'
        if err.message and err.message.match /\s*Cannot resolve profile/i
          throw new Error "ASK profile '#{askProfile}' not found. Make sure the profile exists and
            was correctly configured with ask init."
        else
          return Promise.reject(err)

      # else, err was a string which means it's the SMAPI call's stderr output
      if version.major < 2
        code = undefined
        message = undefined
        name = ''
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
        catch err2
          logger.error "failed to extract failure code and message from SMAPI call: #{err2}"
      else
        # starting v2, the error may be a service response JSON error, or it may be a local one
        prefix = "[Error]: "
        offset = err.indexOf prefix
        if offset >= 0
          try
            err = err[offset + prefix.length ..]
            parsed = JSON.parse err
            code = parsed.statusCode
            message = parsed.message
            name = parsed.name
          catch err2
            logger.error "failed to extract failure code and message from SMAPI call: #{err2}"
        else
          message = err

      unless message
        message = "Unknown SMAPI error during command '#{command}': #{err}"

      Promise.reject { code, message, name }

  spawnPromise: (cmd, args) ->
    return new Promise (resolve, reject) =>
      spawnedProcess = spawn(cmd, args, {shell:true})

      stdout = null
      stderr = ''

      spawnedProcess.on('error', (err) ->
        if err.code == 'ENOENT'
          throw new Error "Unable to run 'ask'. Is the ask-cli installed and configured
            correctly?"
        else
          throw err
      )
      spawnedProcess.stdout.on('data', (data) ->
        if stdout == null
          if typeof(data) == 'object'
            # observed a binary response here, if so accumulate bytes instead
            stdout = data
            return
          else
            stdout = ''

        if typeof(data) == 'object'
          stdout = Buffer.concat [ stdout, data ]
        else
          stdout += data
      )
      spawnedProcess.stderr.on('data', (data) ->
        stderr += data
      )

      resolver = ->
        if stdout == null
          stdout = ''
        if typeof(stdout) == 'object'
          stdout = stdout.toString('utf8')

        resolve {
          stdout,
          stderr
        }

      spawnedProcess.on('exit', resolver)
      spawnedProcess.on('close', resolver)
}
