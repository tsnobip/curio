%%raw("import './index.css'")

open Xote

let _ = {
  Router.init()
  Auth.initialize()->Promise.then(_ => {
    switch Signal.peek(Auth.session) {
    | Some({did, agent}) =>
      let _ = Ratings.loadForUser(did, agent)
      let _ = Wishlist.loadForUser(did, agent)
      Promise.resolve()
    | None => Promise.resolve()
    }
  })->ignore
  Component.mountById(<App />, "root")
}
