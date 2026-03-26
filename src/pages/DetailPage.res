// Shared detail rendering for both Movie and TV
module MediaInfo = {
  @jsx.component
  let make = (
    ~poster: option<string>,
    ~title: string,
    ~year: string,
    ~meta: string,
    ~voteAverage: float,
    ~genres: string,
    ~tagline: option<string>,
    ~overview: string,
  ) => {
    <div className="flex flex-col md:flex-row gap-8">
      {switch poster {
      | Some(path) =>
        <img
          src={Tmdb.imageUrl(path)}
          alt={title}
          className="w-full max-w-96 sm:max-w-64 rounded-lg shadow-lg ring-1 ring-gray-800 shrink-0"
        />
      | None =>
        <div
          className="w-64 h-96 rounded-lg bg-gray-800 flex items-center justify-center text-gray-500"
        >
          {Hjsx.string("No poster")}
        </div>
      }}
      <div className="flex-1">
        <h1 className="text-3xl font-bold text-gray-100 mb-1"> {Hjsx.string(title)} </h1>
        <div className="flex items-center gap-3 text-sm text-gray-400 mb-4">
          <span> {Hjsx.string(year)} </span>
          <span> {Hjsx.string(meta)} </span>
          <Rating rating={Average(voteAverage)} />
        </div>
        <div className="text-sm text-gray-500 mb-4"> {Hjsx.string(genres)} </div>
        {switch tagline {
        | Some(t) if t != "" => <p className="text-curio-400 italic mb-4"> {Hjsx.string(t)} </p>
        | _ => Hjsx.null
        }}
        <p className="text-gray-300 leading-relaxed"> {Hjsx.string(overview)} </p>
      </div>
    </div>
  }
}

module Actions = {
  @jsx.component
  let make = (
    ~tmdbId: int,
    ~mediaType: string,
    ~title: string,
    ~posterPath: string,
    ~currentRating: int,
    ~currentReview: option<string>,
    ~isFavorite: bool,
    ~inWatchlist: bool,
    ~rateEndpoint: Handlers.hxPost,
    ~wishlistEndpoint: Handlers.hxPost,
    ~favoriteEndpoint: Handlers.hxPost,
  ) => {
    <div className="flex items-center gap-4 flex-wrap">
      <StarRating tmdbId mediaType title posterPath currentRating currentReview rateEndpoint />
      <FavoriteButton tmdbId mediaType title posterPath isFavorite favoriteEndpoint />
      <WatchlistButton tmdbId mediaType title posterPath inWatchlist wishlistEndpoint />
    </div>
  }
}

@jsx.component
let make = async (
  ~mediaType: string,
  ~id: string,
  ~apiKey: string,
  ~session: option<Session.t>,
  ~rateEndpoint: Handlers.hxPost,
  ~wishlistEndpoint: Handlers.hxPost,
  ~favoriteEndpoint: Handlers.hxPost,
) => {
  let idNum = Int.fromString(id)->Option.getOr(0)

  let detail = try {
    if mediaType == "tv" {
      Some(await Tmdb.fetchTv(apiKey, idNum))
    } else {
      Some(await Tmdb.fetchMovie(apiKey, idNum))
    }
  } catch {
  | JsExn(e) =>
    Console.error2("Error fetching detail", e)
    None
  }

  let (currentRating, currentReview) = switch session {
  | Some(s) =>
    try {
      let agent = await OAuth.restoreAgent(s.did)
      let resp = await AtProto.Rating.list(agent, s.did)
      let found =
        resp.data.records->Array.find(r =>
          r.value.tmdbId == idNum && r.value.mediaType == mediaType
        )
      (
        found->Option.map(r => r.value.rating)->Option.getOr(0),
        found->Option.flatMap(r => r.value.review),
      )
    } catch {
    | JsExn(e) =>
      Console.error2("Error loading ratings", e)
      (0, None)
    }
  | None => (0, None)
  }

  let inWatchlist = switch session {
  | Some(s) =>
    try {
      let agent = await OAuth.restoreAgent(s.did)
      let resp = await AtProto.Watchlist.list(agent, s.did)
      resp.data.records->Array.some(w => w.value.tmdbId == idNum && w.value.mediaType == mediaType)
    } catch {
    | JsExn(e) =>
      Console.error2("Error loading wishlist", e)
      false
    }
  | None => false
  }

  let isFavorite = switch session {
  | Some(s) =>
    try {
      let agent = await OAuth.restoreAgent(s.did)
      let resp = await AtProto.Favorite.list(agent, s.did)
      resp.data.records->Array.some(f => f.value.tmdbId == idNum && f.value.mediaType == mediaType)
    } catch {
    | JsExn(e) =>
      Console.error2("Error loading favorites", e)
      false
    }
  | None => false
  }

  let communityReviews = ReviewStore.getForMedia(
    ~mediaKey=ReviewStore.mediaKey(~mediaType, ~tmdbId=idNum),
    ~excludeDid=?session->Option.map(s => s.did),
  )

  let (title, posterPath) = switch detail {
  | Some(Movie(m)) => (m.title, m.posterPath->Option.getOr(""))
  | Some(Tv(t)) => (t.name, t.posterPath->Option.getOr(""))
  | None => ("", "")
  }

  switch detail {
  | None =>
    <div className="max-w-4xl mx-auto px-4 sm:px-8 py-8">
      <div className="flex justify-center py-20">
        <div className="text-gray-500"> {Hjsx.string("Not found")} </div>
      </div>
    </div>
  | Some(Movie(m)) =>
    <div className="max-w-4xl mx-auto px-4 sm:px-8 py-8 space-y-8">
      <MediaInfo
        poster={m.posterPath}
        title={m.title}
        year={switch m.releaseDate {
        | Some(d) if d->String.length >= 4 => d->String.slice(~start=0, ~end=4)
        | _ => ""
        }}
        meta={switch m.runtime {
        | Some(r) => `${Int.toString(r)} min`
        | None => ""
        }}
        voteAverage={m.voteAverage}
        genres={m.genres->Array.map(g => g.name)->Array.join(", ")}
        tagline={m.tagline}
        overview={m.overview->Option.getOr("")}
      />
      {switch session {
      | Some(_) =>
        <div className="user-actions space-y-8">
          <Actions
            tmdbId={m.id}
            mediaType="movie"
            title
            posterPath
            currentRating
            currentReview
            isFavorite
            inWatchlist
            rateEndpoint
            wishlistEndpoint
            favoriteEndpoint
          />
          <ReviewSection.MyReview
            tmdbId={m.id}
            mediaType="movie"
            title
            posterPath
            currentRating
            currentReview
            rateEndpoint
          />
        </div>
      | None =>
        <a
          href="/login"
          className="inline-block px-4 py-2 text-sm rounded-lg bg-gray-800 hover:bg-gray-700 text-gray-300 transition-colors"
        >
          {Hjsx.string("Sign in to rate and review")}
        </a>
      }}
      <ReviewSection reviews=communityReviews />
    </div>
  | Some(Tv(t)) =>
    <div className="max-w-4xl mx-auto px-4 py-8 space-y-8">
      <MediaInfo
        poster={t.posterPath}
        title={t.name}
        year={switch t.firstAirDate {
        | Some(d) if d->String.length >= 4 => d->String.slice(~start=0, ~end=4)
        | _ => ""
        }}
        meta={switch t.numberOfSeasons {
        | Some(n) => `${Int.toString(n)} ${n == 1 ? "season" : "seasons"}`
        | None => ""
        }}
        voteAverage={t.voteAverage}
        genres={t.genres->Array.map(g => g.name)->Array.join(", ")}
        tagline={t.tagline}
        overview={t.overview}
      />
      {switch session {
      | Some(_) =>
        <div className="user-actions space-y-8">
          <Actions
            tmdbId={t.id}
            mediaType="tv"
            title
            posterPath
            currentRating
            currentReview
            isFavorite
            inWatchlist
            rateEndpoint
            wishlistEndpoint
            favoriteEndpoint
          />
          <ReviewSection.MyReview
            tmdbId={t.id} mediaType="tv" title posterPath currentRating currentReview rateEndpoint
          />
        </div>
      | None =>
        <a
          href="/login"
          className="inline-block px-4 py-2 text-sm rounded-lg bg-gray-800 hover:bg-gray-700 text-gray-300 transition-colors"
        >
          {Hjsx.string("Sign in to rate and review")}
        </a>
      }}
      <ReviewSection reviews=communityReviews />
    </div>
  }
}
