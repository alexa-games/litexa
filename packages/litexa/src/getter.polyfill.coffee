# Coffee shim for es6 getter behavior

Function::getter = (prop, get) ->
  Object.defineProperty @prototype, prop, {get, configurable: yes}
