type store = {
  set: (string, JSON.t) => promise<unit>,
  get: string => promise<option<JSON.t>>,
  del: string => promise<unit>,
}

module type Impl = {
  let stateStore: store
  let sessionStore: store
  let requestLock: option<unit => promise<unit>>
}
