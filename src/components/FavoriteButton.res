@jsx.component
let make = (
  ~tmdbId: int,
  ~mediaType: string,
  ~title: string,
  ~posterPath: string,
  ~isFavorite: bool,
  ~favoriteEndpoint: Handlers.hxPost,
) => {
  <form className="favorite-btn" id={`favorite-${Int.toString(tmdbId)}-${mediaType}`}>
    <input type_="hidden" name="tmdbId" value={Int.toString(tmdbId)} />
    <input type_="hidden" name="mediaType" value={mediaType} />
    <input type_="hidden" name="title" value={title} />
    <input type_="hidden" name="posterPath" value={posterPath} />
    <input
      type_="hidden"
      name="action"
      value={if isFavorite { "remove" } else { "add" }}
    />
    <button
      type_="submit"
      hxPost={favoriteEndpoint}
      hxTarget={Htmx.Target.make(Closest({cssSelector: ".favorite-btn"}))}
      hxSwap={Htmx.Swap.make(OuterHTML)}
      title={if isFavorite { "Remove from favorites" } else { "Add to favorites" }}
      className={"text-2xl transition-colors " ++
      if isFavorite {
        "text-heart"
      } else {
        "text-gray-600 hover:text-heart"
      }}
    >
      {Hjsx.string(if isFavorite { "♥" } else { "♡" })}
    </button>
  </form>
}
