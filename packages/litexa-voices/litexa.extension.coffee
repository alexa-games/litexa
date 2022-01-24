module.exports = (options, lib) ->
  openUnlessContent = (part) =>
    part.open = true
    if part.content?.trim().length > 0
      part.open = false

  return 
    language: 
      sayTags:
        quickly: 
          process: (part) ->
            part.tag = "prosody"
            part.attributes =
              rate: "fast"
            openUnlessContent(part)
        slowly:
          process: (part) ->
            part.tag = "prosody"
            part.attributes =
              rate: "slow"
            openUnlessContent(part)
        baritone:
          process: (part) ->
            part.tag = "prosody"
            part.attributes =
              pitch: "low"
            openUnlessContent(part)
        voice: 
          process: (part) ->
            part.tag = "voice"
            part.attributes = 
              name: part.content
            openUnlessContent(part)
        Matthew: 
          process: (part) ->
            #part.tag = "voice"
            part.attributes = 
              name: "Matthew"
            openUnlessContent(part)
            part.proxy = 
              toSSML: ->
                if part.open
                  "<voice name='Matthew'><amazon:domain name='conversational'>"
                else 
                  "<voice name='Matthew'><amazon:domain name='conversational'>#{part.content}</amazon:domain></voice>"
              closeSSML: ->
                "</amazon:domain></voice>"
        Brian: 
          process: (part) ->
            part.tag = "voice"
            part.attributes = 
              name: "Brian"
            openUnlessContent(part)
        excited:
          process: (part) ->
            part.tag = "amazon:emotion"
            part.attributes =
              name: "excited"
              intensity: "high"
            openUnlessContent(part)
            



