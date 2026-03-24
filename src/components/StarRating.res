open Xote

@jsx.component
let make = (~tmdbId, ~mediaType, ~title, ~posterPath) => {
  let hovered = Signal.make(0)

  let stars = Computed.make(() => {
    let currentRating = switch Ratings.getRating(tmdbId, mediaType) {
    | Some(r) => r.rating
    | None => 0
    }
    let hoveredStar = Signal.get(hovered)

    Array.fromInitializer(~length=5, i => {
      let star = i + 1
      let filled = hoveredStar > 0 ? star <= hoveredStar : star <= currentRating

      <button
        class={"text-2xl transition-colors " ++ (
          filled ? "text-gold-400" : "text-gray-600 hover:text-gold-500"
        )}
        onClick={_evt => {
          if star == currentRating {
            Ratings.remove(~tmdbId, ~mediaType)->ignore
          } else {
            Ratings.rate(~tmdbId, ~mediaType, ~rating=star, ~title, ~posterPath)->ignore
          }
        }}
        onMouseEnter={_evt => Signal.set(hovered, star)}
        onMouseLeave={_evt => Signal.set(hovered, 0)}
      >
        {Component.text(filled ? "\u2605" : "\u2606")}
      </button>
    })
  })

  <div class="flex gap-0.5"> {Component.signalFragment(stars)} </div>
}
