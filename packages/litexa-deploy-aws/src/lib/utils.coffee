minimatch = require 'minimatch'

hasKeys = (obj, keys) ->
  if not obj or not keys
    return false

  for key in Object.keys(obj)
    if keys.includes key
      return true
  return false


matchesGlobPatterns = (fileName, globPatterns) ->
  if not fileName or not globPatterns
    return false

  for pattern in globPatterns
    # matchBase includes files at the end of paths
    # e.g. so html/bundle.js matches *.js
    if minimatch(fileName, pattern, { matchBase: true })
      return true
  return false


module.exports = {
  hasKeys
  matchesGlobPatterns
}
