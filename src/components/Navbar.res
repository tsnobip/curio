open Xote

@jsx.component
let make = () => {
  let userLinks = Computed.make(() => {
    switch Signal.get(Auth.session) {
    | Some({handle}) => [
        <Router.Link
          to={"/@" ++ handle ++ "/ratings"}
          class="text-sm text-gray-400 hover:text-gray-100 transition-colors"
        >
          {Component.text("My Ratings")}
        </Router.Link>,
        <Router.Link
          to={"/@" ++ handle ++ "/wishlist"}
          class="text-sm text-gray-400 hover:text-gray-100 transition-colors"
        >
          {Component.text("My Wishlist")}
        </Router.Link>,
      ]
    | None => []
    }
  })

  <nav class="border-b border-gray-800 bg-gray-950/80 backdrop-blur-sm sticky top-0 z-50">
    <div class="max-w-6xl mx-auto px-4 h-14 flex items-center justify-between">
      <div class="flex items-center gap-6">
        <Router.Link to="/" class="text-xl font-bold text-curio-400 tracking-tight">
          {Component.text("Curio")}
        </Router.Link>
        {Component.signalFragment(userLinks)}
      </div>
      <LoginButton />
    </div>
  </nav>
}
