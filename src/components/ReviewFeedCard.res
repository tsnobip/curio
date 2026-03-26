module Avatar = {
  @jsx.component
  let make = (~handle, ~avatar: option<string>, ~size="h-8 w-8 text-sm") => {
    let handle = Handle.toString(handle)
    let letter =
      handle->String.startsWith("@")
        ? handle->String.get(1)->Option.getOr("?")->String.toUpperCase
        : "?"

    switch avatar {
    | Some(url) if url != "" =>
      <img src={url} alt={handle} className={`rounded-full object-cover ${size}`} />
    | _ =>
      <div
        className={`rounded-full bg-curio-700 flex items-center justify-center font-medium text-curio-200 ${size}`}
      >
        {Hjsx.string(letter)}
      </div>
    }
  }
}

@jsx.component
let make = (~review: ReviewStore.review, ~showMedia=true) => {
  let mediaRoute = `/${review.mediaType}/${Int.toString(review.tmdbId)}`
  let userRoute = `/${review.handle->Handle.toString}`

  <div className="flex gap-3">
    // Poster thumbnail
    {if showMedia {
      <a href={mediaRoute} className="shrink-0">
        {if review.posterPath != "" {
          <img
            src={Tmdb.imageUrl(review.posterPath)}
            alt={review.title}
            className="w-30 h-45 rounded object-cover ring-1 ring-gray-800"
          />
        } else {
          <div
            className="w-30 h-45 rounded bg-gray-800 flex items-center justify-center text-gray-600 text-xs"
          >
            {Hjsx.string("?")}
          </div>
        }}
      </a>
    } else {
      Hjsx.null
    }}
    // Content
    <div className="flex-1 min-w-0 flex flex-col gap-1">
      {if showMedia {
        <a
          href={mediaRoute}
          className="text-lg font-bold text-gray-200 hover:text-curio-400 truncate block"
        >
          {Hjsx.string(review.title)}
        </a>
      } else {
        Hjsx.null
      }}
      <div className="flex items-center gap-2">
        <a href={userRoute} className="shrink-0">
          <Avatar handle={review.handle} avatar={review.avatar} />
        </a>
        <div className="min-w-0 flex flex-col items-start">
          <a
            href={userRoute}
            className="text-sm font-medium text-gray-300 hover:text-curio-400 truncate"
          >
            {Hjsx.string(review.handle->Handle.toString)}
          </a>
          <Rating rating={Individual(review.rating)} />
        </div>
      </div>
      {switch review.review {
      | Some(r) if r != "" =>
        <p
          className={`mt-1 text-sm text-gray-400 leading-relaxed whitespace-pre-wrap ${showMedia
              ? "line-clamp-4"
              : ""}`}
        >
          {Hjsx.string(r)}
        </p>
      | _ => Hjsx.null
      }}
    </div>
  </div>
}
