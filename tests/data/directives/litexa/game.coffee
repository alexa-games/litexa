makeSingleDirective = ->
  return
    type: "AudioPlayer.Play"


makeMultipleDirectives = ->
  return [
    {
      type: "Hint"
    },
    {
      type: "AudioPlayer.Stop"
    }
  ]