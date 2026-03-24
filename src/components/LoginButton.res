open Xote

@jsx.component
let make = () => {
  let handleInput = Signal.make("")
  let loggingIn = Signal.make(false)

  let onInput = evt => Signal.set(handleInput, Util.inputValue(evt))

  let onLogin = _evt => {
    let handle = Signal.peek(handleInput)->String.trim
    if handle != "" {
      Signal.set(loggingIn, true)
      Auth.login(handle)
      ->Promise.then(_ => {
        Signal.set(loggingIn, false)
        Promise.resolve()
      })
      ->ignore
    }
  }

  let onKeyDown = evt => {
    if Util.keyboardKey(evt) == "Enter" {
      onLogin(evt)
    }
  }

  let onLogout = _evt => Auth.logout()->ignore

  Component.signalFragment(
    Computed.make(() => {
      switch Signal.get(Auth.session) {
      | Some({handle}) => [
          <div class="flex items-center gap-3">
            <span class="text-sm text-gray-300"> {Component.text("@" ++ handle)} </span>
            <button
              class="px-3 py-1.5 text-sm rounded-lg bg-gray-800 hover:bg-gray-700 text-gray-300 transition-colors"
              onClick={onLogout}
            >
              {Component.text("Log out")}
            </button>
          </div>,
        ]
      | None => [
          <div class="flex items-center gap-2">
            <input
              type_="text"
              placeholder="handle.bsky.social"
              class="px-3 py-1.5 text-sm rounded-lg bg-gray-800 border border-gray-700 text-gray-100 placeholder-gray-500 focus:outline-none focus:border-curio-500"
              onInput={onInput}
              onKeyDown={onKeyDown}
            />
            <button
              class="px-3 py-1.5 text-sm rounded-lg bg-curio-600 hover:bg-curio-500 text-white font-medium transition-colors"
              onClick={onLogin}
            >
              {Component.textSignal(() => Signal.get(loggingIn) ? "Signing in..." : "Sign in")}
            </button>
          </div>,
        ]
      }
    }),
  )
}
