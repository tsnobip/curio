let maxRating = 10

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
  let id = `rating-${Int.toString(tmdbId)}-${mediaType}`

  // Stars in reverse DOM order, displayed with flex-direction: row-reverse.
  // CSS ~ selector highlights "previous" stars on hover.
  let stars = Array.fromInitializer(~length=maxRating, i => {
    let star = maxRating - i
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
        value={if star == currentRating {
          "0"
        } else {
          Int.toString(star)
        }}
      />
      <button
        type_="submit"
        hxPost={rateEndpoint}
        hxTarget={Htmx.Target.make(Closest({cssSelector: ".user-actions"}))}
        hxSwap={Htmx.Swap.make(OuterHTML)}
        __rawProps={dict{"data-star": Int.toString(star)->JSON.String}}
        className={`relative text-lg transition-colors cursor-pointer
        group-hover/stars:text-gray-600 [.star-form:hover_&]:text-gold-400
         [.star-form:hover~.star-form_&]:text-gold-400 after:content-[attr(data-star)]
          after:absolute after:bottom-full after:left-1/2 after:-translate-x-1/2 after:px-2
          after:py-1 after:rounded after:text-xs after:leading-tight after:whitespace-nowrap
           after:bg-gray-800 after:text-gray-300 after:opacity-0 after:pointer-events-none
           after:transition-opacity hover:after:opacity-100 ${filled
            ? "text-gold-400"
            : "text-gray-600"}`}
      >
        {Hjsx.string(filled ? "★" : "☆")}
      </button>
    </form>
  })

  let ratingLabel = if currentRating > 0 {
    <span className="text-sm text-gray-400 ml-1.5">
      {Hjsx.string(`${Int.toString(currentRating)}/${Int.toString(maxRating)}`)}
    </span>
  } else {
    Hjsx.null
  }

  <div className="star-rating group/stars" id>
    <div className="flex flex-row-reverse justify-end items-center">
      {stars->Hjsx.array}
      {ratingLabel}
    </div>
  </div>
}
