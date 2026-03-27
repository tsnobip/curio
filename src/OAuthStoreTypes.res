type store = {
  set: (string, JSON.t) => promise<unit>,
  get: string => promise<option<JSON.t>>,
  del: string => promise<unit>,
}

module type Impl = {
  let stateStore: store
  let sessionStore: store
  /** Stored widened for typing; runtime is `(name, fn) => …` for NodeOAuthClient */
  let requestLock: option<(string, unit => promise<unit>) => promise<unit>>
}
