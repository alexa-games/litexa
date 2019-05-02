### gameplay logic ###

black = '000000'
white = 'FEFEFF'
blue = '0000DD'
bblue = '0000FE'
red = 'FE0000'
rred = 'FF99AA'
green = '00FE00'
orange = 'FEAA00'


rollCallDuration = 60000


class Game
  constructor: () ->
    @buttons = @buttons ? []

  reset: ->
    @buttons = []

  rollCallDirective: (numberOfButtons) ->
    try
      numberOfButtons = parseInt(numberOfButtons)
    catch
      numberOfButtons = 2
    @requestedNumberOfButtons = numberOfButtons
    @buttons = []
    proxies = []
    pattern = []
    for i in [0...numberOfButtons]
      name = "btn#{i}"
      proxies.push name
      pattern.push { gadgetIds:[name], action: 'down' }

    # We've written our Input Handler for simplicity in both this code and Litexa code.
    # However, it will receive button presses from already-pressed buttons.
    # If the user spams button presses, we want to stop getting these Input Handler events for the session
    # with an arbitrary limit of number of buttons * 12.
    # If you're curious about another way to write an Input Handler, scroll down to
    # alternativeRollCallDirective.
    inputHandler =
      type: "GameEngine.StartInputHandler"
      timeout: rollCallDuration
      proxies: proxies
      maximumHistoryLength: 100
      recognizers:
        "button pressed":
          type: "match"
          fuzzy: false
          anchor: "end"
          pattern: [ { gadgetIds:proxies, action: 'down' } ]
        "all pressed":
          type: "match"
          fuzzy: true
          anchor: "start"
          pattern: pattern
      events:
        "NewButton":
          meets: [ "button pressed" ]
          fails: [ "all pressed" ]
          reports: "history"
          maximumInvocations: numberOfButtons * 12
          shouldEndInputHandler: false
        "Timedout":
          meets: [ "timed out" ]
          reports: "history"
          shouldEndInputHandler: true
        "Finished":
          meets: [ "all pressed" ]
          reports: "matches"
          shouldEndInputHandler: true

    inputHandler

  hasCompletedRollCall: ->
    return false unless @requestedNumberOfButtons?
    return @buttons?.length == @requestedNumberOfButtons

  buttonCount: ->
    @buttons?.length ? 0

  registerButtons: (event) ->
    oldButtonCount = @buttons.length
    @newButtons = []
    for e in event.inputEvents
      unless e.gadgetId in @buttons
        @buttons.push e.gadgetId
        @newButtons.push e.gadgetId
    if @buttons.length == @requestedNumberOfButtons
      reportValueMetric("roll-call-buttons", @requestedNumberOfButtons)
    @buttons.length > oldButtonCount

  lightUpNewButtons: ->
    return [] unless @newButtons? and @newButtons.length > 0
    animationFromArray = gadgetController.animationFromArray
    anim = animationFromArray [
      [ "FFFFFF", 10, true ]
      [ orange, 500, true ]
      [ orange, rollCallDuration, false ]
    ]
    directives = []
    directives = directives.concat gadgetController.resetTriggersDirectives(@newButtons)
    directives.push gadgetController.directive(@newButtons, 1, anim)
    directives

  # it's a good design practice to acknowledge the last button in roll call before
  # moving on to the starting game animation
  startGame: (acknowledgeLastButton) ->
    @winningIndex = randomIndex(@buttons.length)
    winningId = @buttons[@winningIndex]
    #console.debug "the red button is: #{@winningIndex}, #{winningId}"

    [ totalDuration, animations ] = @buildGameAnimationDirectives()

    inputHandler =
      type: "GameEngine.StartInputHandler"
      timeout: totalDuration
      maximumHistoryLength: 100
      recognizers:
        "winner":
          type: "match"
          fuzzy: true
          anchor: "start"
          pattern: [
            {
              action: 'down'
              colors: [ green ]
              gadgetIds: [ winningId ]
            }
          ]
        "losers":
          type: "match"
          fuzzy: true
          pattern: [
            {
              action: 'down'
              colors: [ green ]
              gadgetIds: ( i for i in @buttons when i != winningId )
            }
          ]
      events:
        "win":
          meets: [ "winner" ]
          reports: "matches"
          shouldEndInputHandler: true
        "lose":
          meets: [ "losers" ]
          reports: "matches"
          shouldEndInputHandler: true
        "timeout":
          meets: [ "timed out" ]
          reports: "history"
          shouldEndInputHandler: true

    # modify the last button's animation after it's constructed
    if acknowledgeLastButton
      lastButton = @buttons[@buttons.length-1]
      if animations[0].targetGadgets[0] == lastButton
        animations[0].parameters.animations[0].sequence[0].color = "FFFFFF"
        animations[0].parameters.animations[0].sequence[0].blend = true
        animations[0].parameters.animations[0].sequence[1].color = orange
        animations[0].parameters.animations[0].sequence[2].color = orange
        animations[0].parameters.animations[0].sequence[2].blend = false
        animations[0].parameters.animations[0].sequence[3].blend = false
      else
        lastButtonAnimation = JSON.parse JSON.stringify animations[1]
        directives = [
          inputHandler
          animations[0]
          lastButtonAnimation
        ]
        # if targetGadgets == [], the Gadget Controller API interprets this
        # to mean applicable to all gadgets. We don't want to send a
        # directive with this condition, so we check for this edge case.
        if animations[1].targetGadgets.length > 1
          indexOfLastButton = animations[1].targetGadgets.indexOf(lastButton)
          animations[1].targetGadgets.splice(indexOfLastButton,1)
          lastButtonAnimation.targetGadgets = [lastButton]
          directives.push animations[1]

        lastButtonAnimation.parameters.animations[0].sequence[0].color = "FFFFFF"
        lastButtonAnimation.parameters.animations[0].sequence[0].blend = true
        lastButtonAnimation.parameters.animations[0].sequence[1].color = orange
        lastButtonAnimation.parameters.animations[0].sequence[2].color = orange
        lastButtonAnimation.parameters.animations[0].sequence[2].blend = false
        lastButtonAnimation.parameters.animations[0].sequence[3].blend = false
        return directives

    return [
      inputHandler
      animations[0]
      animations[1]
    ]

  resultDirectives: ->
    animations = @buildReportAnimationDirectives()
    return [
      animations[0]
      animations[1]
    ]

  packWinnerLoserAnimations: (win, lose) ->
    winningId = @buttons[@winningIndex]
    winnerButtons = [ winningId ]
    loserButtons = ( i for i in @buttons when i != winningId )

    build = gadgetController.directive
    winner = build(winnerButtons, 1, win)
    losers = build(loserButtons, 1, lose)

    return [ winner, losers ]

  buildGameAnimationDirectives: ->
    show = 5000
    shuffle = 10000
    wait = 5000

    animationFromArray = gadgetController.animationFromArray
    loseData = [
      [ black,       10,  false ]
      [ blue,        50,  true  ]
      [ blue,        100,  true  ]
      [ blue,        50,  true  ]
      [ blue,        400,  true  ]
      [ blue,        50,  true  ]
      [ blue,        800,  true  ]
      [ blue,      show,  false ]
      [ orange,     100,  true  ]
      [ orange, shuffle,  false ]
      [ green,      100,  true  ]
      [ green,     wait,  false ]
      [ green,     wait,  false ]
      [ green,     wait,  false ]
      [ black,      200,  true  ]
    ]
    lose = animationFromArray loseData
    totalDuration = 0
    for i in loseData
      totalDuration += i[1]

    win = animationFromArray [
      [ black,       10,  false ]
      [ red,         50,  true  ]
      [ rred,        100,  true  ]
      [ rred,        50,  true  ]
      [ red,         400,  true  ]
      [ rred,        50,  true  ]
      [ red,         800,  true  ]
      [ red,       show,  false ]
      [ orange,     100,  true  ]
      [ orange, shuffle,  false ]
      [ green,      100,  true  ]
      [ green,     wait,  false ]
      [ green,     wait,  false ]
      [ green,     wait,  false ]
      [ black,      200,  true  ]
    ]

    return [ totalDuration, @packWinnerLoserAnimations(win, lose) ]


  buildReportAnimationDirectives: ->
    hold = 5000
    animationFromArray = gadgetController.animationFromArray
    lose = animationFromArray [
      [ black,        1,  false ]
      [ bblue,      100,  true  ]
      [ blue,       500,  true  ]
      [ blue,      hold,  true  ]
      [ black,      700,  true  ]
    ]

    win = animationFromArray [
      [ black,        1,  false ]
      [ white,       50,  true  ]
      [ red,        400,  true  ]
      [ white,       50,  true  ]
      [ red,        500,  true  ]
      [ white,       50,  true  ]
      [ red,        700,  true  ]
      [ red,       hold,  true  ]
      [ black,      700,  true  ]
    ]

    return @packWinnerLoserAnimations(win, lose)

  ###
    We aren't using this in this example, but this is another option for roll call
    with the opposite pros and cons of the other one. It guarantees 1 event
    per unique button press, but you do need to have 4 of them to replace the
    "NewButton" event - one for each InputHandlerEvent that may come through.

    If you choose to do it this way, it is a good practice to not write repeat code, so
    for each InputHandlerEvent handler, create and have each handler go to a common state
    that handles the combined "NewButton" and "Finished" logic that routes back to roll call
    to listen for more InputHandlerEvents.
  ###
  alternativeRollCallDirective: (numberOfButtons) ->
    try
      numberOfButtons = parseInt(numberOfButtons)
    catch
      numberOfButtons = 2
    @requestedNumberOfButtons = numberOfButtons
    @buttons = []
    proxies = []
    recognizers = {}
    events = {}
    for i in [0...numberOfButtons]
      name = "btn#{i}"
      recognizerName = "button #{i}"
      eventName = "button #{i} pressed"
      proxies.push name

      recognizers[recognizerName] =
          type: "match"
          fuzzy: false
          anchor: "end"
          pattern: [ { gadgetIds:[name], action: 'down' } ]

      events[eventName] =
          meets: [recognizerName]
          reports: "matches"
          shouldEndInputHandler: i >= numberOfButtons-1
          maximumInvocations: 1

    events["Timedout"] =
      meets: [ "timed out" ]
      reports: "history"
      shouldEndInputHandler: true

    inputHandler =
      type: "GameEngine.StartInputHandler"
      timeout: rollCallDuration
      proxies: proxies
      maximumHistoryLength: 100
      recognizers: recognizers
      events: events

    return inputHandler


dimButtons = ->
  anim = gadgetController.animationFromArray [
    ["FFFFFF", 50,  true]
    ["000000", 500, true]
  ]
  [ gadgetController.directive([], 1, anim, "none") ]


## utility functions for building GadgetController.SetLight directives

gadgetController =
  # Gadget animations are for Echo Buttons right now
  # this is about animating the colors on the buttons
  # with the SetLight directive

  buildKey: (color, duration, blend) ->
    # build the inner key structure of an
    # animation to pass into directive
    color = color[1..] if color[0] == '#'
    return {
      color: color.toUpperCase()
      durationMs: duration
      blend: blend ? true
    }

  animationFromArray: (keyData) ->
    # build an animation array suitable to give
    # the directive function, from an array of
    # arrays of arguments to pass buildKey
    # e.g. [ ['FF0000',1000,true], ['00FFFF',2000,true] ]
    build = gadgetController.buildKey
    for d in keyData
      build d[0], d[1], d[2]

  resetTriggersDirectives: (targets) ->
    [
      gadgetController.directive(targets, 1, [litexa.gadgetAnimation.buildKey("FFFFFF",100,false)], "buttonDown" )
      gadgetController.directive(targets, 1, [litexa.gadgetAnimation.buildKey("FFFFFF",100,false)], "buttonUp" )
    ]

  directive: (targets, repeats, animation, trigger, delay) ->
    # directive to animate Echo buttons
    # hardcode values that aren't changing in the short term
    return
      {
        type: "GadgetController.SetLight"
        version: 1
        targetGadgets: targets
        parameters:
          triggerEvent: trigger ? "none"
          triggerEventTimeMs: delay ? 0
          animations: [
            targetLights: [ "1" ]
            repeat: repeats
            sequence: animation
          ]
      }
