@jsx.component
let make = (
  ~tmdbId: int,
  ~mediaType: string,
  ~title: string,
  ~posterPath: string,
  ~currentRating: int,
  ~currentReview: option<string>,
  ~rateEndpoint: Handlers.hxPost,
) => {
  // Stars rendered in reverse DOM order (5->1), displayed with flex-direction: row-reverse
  // so they appear visually as 1->5. This lets CSS ~ selector highlight "previous" stars on hover.
  let stars = Array.fromInitializer(~length=5, i => {
    let star = 5 - i
    let filled = star <= currentRating

    <form className="star-form">
      <input type_="hidden" name="tmdbId" value={Int.toString(tmdbId)} />
      <input type_="hidden" name="mediaType" value={mediaType} />
      <input type_="hidden" name="title" value={title} />
      <input type_="hidden" name="posterPath" value={posterPath} />
      <input type_="hidden" name="review" value={currentReview->Option.getOr("")} />
      <input
        type_="hidden"
        name="rating"
        value={if star == currentRating { "0" } else { Int.toString(star) }}
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
        {Hjsx.string(if filled { "\u2605" } else { "\u2606" })}
      </button>
    </form>
  })

  let reviewSection = if currentRating > 0 {
    <form className="mt-3">
      <input type_="hidden" name="tmdbId" value={Int.toString(tmdbId)} />
      <input type_="hidden" name="mediaType" value={mediaType} />
      <input type_="hidden" name="title" value={title} />
      <input type_="hidden" name="posterPath" value={posterPath} />
      <input type_="hidden" name="rating" value={Int.toString(currentRating)} />
      <div className="flex gap-2">
        <textarea
          name="review"
          placeholder="Write a review..."
          rows=2
          className="flex-1 px-3 py-2 text-sm rounded-lg bg-gray-900 border border-gray-700 text-gray-200 placeholder-gray-500 focus:outline-none focus:border-curio-500 resize-none"
        >
          {Hjsx.string(currentReview->Option.getOr(""))}
        </textarea>
        <button
          type_="submit"
          hxPost={rateEndpoint}
          hxTarget={Htmx.Target.make(Closest({cssSelector: ".star-rating"}))}
          hxSwap={Htmx.Swap.make(OuterHTML)}
          className="self-end px-3 py-2 text-sm rounded-lg bg-curio-600 hover:bg-curio-500 text-white transition-colors cursor-pointer"
        >
          {Hjsx.string("Save")}
        </button>
      </div>
      {switch currentReview {
      | Some(r) if r != "" =>
        <p className="mt-2 text-sm text-gray-400 italic">
          {Hjsx.string(r)}
        </p>
      | _ => Hjsx.null
      }}
    </form>
  } else {
    Hjsx.null
  }

  <div
    className="star-rating"
    id={"rating-" ++ Int.toString(tmdbId) ++ "-" ++ mediaType}
  >
    <div className="flex flex-row-reverse justify-end gap-0.5">
      {stars->Hjsx.array}
    </div>
    {reviewSection}
  </div>
}
