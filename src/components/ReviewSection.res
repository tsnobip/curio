module MyReview = {
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
    let reviewId = `my-review-${Int.toString(tmdbId)}-${mediaType}`
    let toggleEdit = `{let el=document.getElementById('${reviewId}');el.dataset.editing=el.dataset.editing==='true'?'false':'true'}`

    let hiddenFields =
      <>
        <input type_="hidden" name="tmdbId" value={Int.toString(tmdbId)} />
        <input type_="hidden" name="mediaType" value={mediaType} />
        <input type_="hidden" name="title" value={title} />
        <input type_="hidden" name="posterPath" value={posterPath} />
        <input type_="hidden" name="rating" value={Int.toString(currentRating)} />
      </>

    if currentRating == 0 {
      Hjsx.null
    } else {
      <div
        className="group/review"
        id={reviewId}
        __rawProps={dict{"data-editing": "false"->JSON.String}}
      >
        <h2 className="text-lg font-semibold text-gray-100 mb-3"> {Hjsx.string("My Review")} </h2>
        // Display mode
        <div className="group-data-[editing=true]/review:hidden whitespace-pre-wrap">
          {switch currentReview {
          | Some(r) if r != "" =>
            <div>
              <p className="text-sm text-gray-300 leading-relaxed"> {Hjsx.string(r)} </p>
              <button
                type_="button"
                onClick={toggleEdit}
                className="mt-2 text-xs text-curio-400 hover:text-curio-300 cursor-pointer"
              >
                {Hjsx.string("Edit review")}
              </button>
            </div>
          | _ =>
            <button
              type_="button"
              onClick={toggleEdit}
              className="text-sm text-gray-500 hover:text-gray-300 cursor-pointer"
            >
              {Hjsx.string("Write a review...")}
            </button>
          }}
        </div>
        // Edit mode
        <form className="hidden group-data-[editing=true]/review:block">
          {hiddenFields}
          <div className="flex gap-2">
            <textarea
              name="review"
              placeholder="What did you think?"
              rows=3
              className="flex-1 px-3 py-2 text-sm rounded-lg bg-gray-900 border border-gray-700 text-gray-200 placeholder-gray-500 focus:outline-none focus:border-curio-500 resize-y"
            >
              {Hjsx.string(currentReview->Option.getOr(""))}
            </textarea>
            <div className="flex flex-col gap-1 self-end">
              <button
                type_="submit"
                hxPost={rateEndpoint}
                hxTarget={Htmx.Target.make(Closest({cssSelector: ".user-actions"}))}
                hxSwap={Htmx.Swap.make(OuterHTML)}
                className="px-3 py-2 text-sm rounded-lg bg-curio-600 hover:bg-curio-500 text-white transition-colors cursor-pointer"
              >
                {Hjsx.string(
                  switch currentReview {
                  | Some(r) if r != "" => "Update"
                  | _ => "Save"
                  },
                )}
              </button>
              <button
                type_="button"
                onClick={toggleEdit}
                className="px-3 py-1 text-xs text-gray-500 hover:text-gray-300 cursor-pointer"
              >
                {Hjsx.string("Cancel")}
              </button>
            </div>
          </div>
        </form>
      </div>
    }
  }
}

@jsx.component
let make = (~reviews: array<ReviewStore.review>) => {
  if Array.length(reviews) == 0 {
    Hjsx.null
  } else {
    <div>
      <h2 className="text-lg font-semibold text-gray-100 mb-3">
        {Hjsx.string("Reviews from Curio")}
      </h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {reviews
        ->Array.map(review => <ReviewFeedCard review showMedia=false />)
        ->Hjsx.array}
      </div>
    </div>
  }
}
