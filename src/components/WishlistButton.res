@jsx.component
let make = (
  ~tmdbId: int,
  ~mediaType: string,
  ~title: string,
  ~posterPath: string,
  ~inWishlist: bool,
  ~wishlistEndpoint: Handlers.hxPost,
) => {
  <form className="wishlist-btn" id={"wishlist-" ++ Int.toString(tmdbId) ++ "-" ++ mediaType}>
    <input type_="hidden" name="tmdbId" value={Int.toString(tmdbId)} />
    <input type_="hidden" name="mediaType" value={mediaType} />
    <input type_="hidden" name="title" value={title} />
    <input type_="hidden" name="posterPath" value={posterPath} />
    <input
      type_="hidden"
      name="action"
      value={if inWishlist {
        "remove"
      } else {
        "add"
      }}
    />
    <button
      type_="submit"
      hxPost={wishlistEndpoint}
      hxTarget={Htmx.Target.make(Closest({cssSelector: ".wishlist-btn"}))}
      hxSwap={Htmx.Swap.make(OuterHTML)}
      className={"text-2xl transition-colors " ++ if inWishlist {
        "text-heart"
      } else {
        "text-gray-600 hover:text-heart"
      }}
    >
      {Hjsx.string(
        if inWishlist {
          "\u2665"
        } else {
          "\u2661"
        },
      )}
    </button>
  </form>
}
