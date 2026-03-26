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
        hxTarget={Htmx.Target.make(Closest({cssSelector: ".star-rating"}))}
        hxSwap={Htmx.Swap.make(OuterHTML)}
        __rawProps={dict{"data-star": Int.toString(star)->JSON.Encode.string}}
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
        <p className="mt-2 text-sm text-gray-400 italic"> {Hjsx.string(r)} </p>
      | _ => Hjsx.null
      }}
    </form>
  } else {
    Hjsx.null
  }

  <div
    className="star-rating group/stars" id={`rating-${Int.toString(tmdbId)}-${mediaType}`}
  >
    <div className="flex flex-row-reverse justify-end items-center">
      {stars->Hjsx.array}
      {ratingLabel}
    </div>
    {reviewSection}
  </div>
}
