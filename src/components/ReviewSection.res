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
        __rawProps={dict{"data-editing": "false"->JSON.Encode.string}}
      >
        <h2 className="text-lg font-semibold text-gray-100 mb-3">
          {Hjsx.string("My Review")}
        </h2>
        // Display mode
        <div className="group-data-[editing=true]/review:hidden">
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

module ReviewCard = {
  @jsx.component
  let make = (~rating: AtProto.RatingCollection.t, ~handle: Handle.t, ~avatar: option<string>) => {
    <div className="flex gap-3">
      // Avatar
      {switch avatar {
      | Some(url) =>
        <img
          src={url}
          alt={handle->Handle.toString}
          className="h-8 w-8 rounded-full object-cover shrink-0 mt-0.5"
        />
      | None =>
        let letter =
          handle->Handle.toString->String.get(0)->Option.map(String.make)->Option.getOr("?")->String.toUpperCase
        <div
          className="h-8 w-8 rounded-full bg-curio-700 flex items-center justify-center font-medium text-curio-200 text-sm shrink-0 mt-0.5"
        >
          {Hjsx.string(letter)}
        </div>
      }}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-gray-200">
            {Hjsx.string(handle->Handle.toString)}
          </span>
          <span className="text-xs text-gold-400">
            {Hjsx.string(`★ ${Int.toString(rating.rating)}/10`)}
          </span>
        </div>
        {switch rating.review {
        | Some(r) if r != "" =>
          <p className="mt-1 text-sm text-gray-400 leading-relaxed"> {Hjsx.string(r)} </p>
        | _ => Hjsx.null
        }}
      </div>
    </div>
  }
}

@jsx.component
let make = (~reviews: array<(Handle.t, option<string>, AtProto.RatingCollection.t)>) => {
  if Array.length(reviews) == 0 {
    Hjsx.null
  } else {
    <div>
      <h2 className="text-lg font-semibold text-gray-100 mb-3">
        {Hjsx.string("Reviews from Curio")}
      </h2>
      <div className="space-y-4">
        {reviews
        ->Array.map(((handle, avatar, rating)) => {
          <ReviewCard handle avatar rating />
        })
        ->Hjsx.array}
      </div>
    </div>
  }
}
