Test.expect "Gadget Directives to be validated", ->
  Test.directives "inputHandler", anyButtonHandler()
  Test.directives "setLight", pulseButtons()