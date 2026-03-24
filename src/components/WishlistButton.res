open Xote

@jsx.component
let make = (~tmdbId, ~mediaType, ~title, ~posterPath) => {
  let content = Computed.make(() => {
    let inWishlist = Wishlist.isInWishlist(tmdbId, mediaType)
    let loggedIn = Signal.get(Auth.isLoggedIn)

    if !loggedIn {
      []
    } else {
      [
        <button
          class={"text-2xl transition-colors " ++ (
            inWishlist ? "text-heart" : "text-gray-600 hover:text-heart"
          )}
          onClick={_evt => {
            if Wishlist.isInWishlist(tmdbId, mediaType) {
              Wishlist.remove(~tmdbId, ~mediaType)->ignore
            } else {
              Wishlist.add(~tmdbId, ~mediaType, ~title, ~posterPath)->ignore
            }
          }}
        >
          {Component.text(inWishlist ? "\u2665" : "\u2661")}
        </button>,
      ]
    }
  })

  Component.signalFragment(content)
}
