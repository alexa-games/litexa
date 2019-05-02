# Coffee shim for es6 setter behavior

Function::setter = (prop, set) ->
  Object.defineProperty @prototype, prop, {set, configurable: yes}
