@jsx.component
let make = (
  ~tmdbId: int,
  ~mediaType: string,
  ~title: string,
  ~posterPath: string,
  ~currentRating: int,
  ~rateEndpoint: Handlers.hxPost,
) => {
  // Stars rendered in reverse DOM order (5→1), displayed with flex-direction: row-reverse
  // so they appear visually as 1→5. This lets CSS ~ selector highlight "previous" stars on hover.
  let stars = Array.fromInitializer(~length=5, i => {
    let star = 5 - i
    let filled = star <= currentRating

    <form className="star-form">
      <input type_="hidden" name="tmdbId" value={Int.toString(tmdbId)} />
      <input type_="hidden" name="mediaType" value={mediaType} />
      <input type_="hidden" name="title" value={title} />
      <input type_="hidden" name="posterPath" value={posterPath} />
      <input
        type_="hidden"
        name="rating"
        value={if star == currentRating {
          "0"
        } else {
          Int.toString(star)
        }}
      />
      <button
        type_="submit"
        hxPost={rateEndpoint}
        hxTarget={Htmx.Target.make(Closest({cssSelector: ".star-rating"}))}
        hxSwap={Htmx.Swap.make(OuterHTML)}
        className={"star-btn text-2xl transition-colors cursor-pointer " ++
        if filled {
          "text-gold-400"
        } else {
          "text-gray-600"
        }}
      >
        {Hjsx.string(
          if filled {
            "\u2605"
          } else {
            "\u2606"
          },
        )}
      </button>
    </form>
  })

  <div
    className="star-rating flex flex-row-reverse justify-end gap-0.5"
    id={"rating-" ++ Int.toString(tmdbId) ++ "-" ++ mediaType}
  >
    {stars->Hjsx.array}
  </div>
}
