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
      let ratings = resp.data.records
      let found =
        ratings->Array.find(r => r.value.tmdbId == idNum && r.value.mediaType == mediaType)
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
      let items = resp.data.records
      items->Array.some(w => w.value.tmdbId == idNum && w.value.mediaType == mediaType)
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
      let favs = resp.data.records
      favs->Array.some(f => f.value.tmdbId == idNum && f.value.mediaType == mediaType)
    } catch {
    | JsExn(e) =>
      Console.error2("Error loading favorites", e)
      false
    }
  | None => false
  }

  switch detail {
  | None =>
    <div className="max-w-4xl mx-auto px-4 py-8">
      <div className="flex justify-center py-20">
        <div className="text-gray-500"> {Hjsx.string("Not found")} </div>
      </div>
    </div>
  | Some(Movie(m)) =>
    <div className="max-w-4xl mx-auto px-4 py-8">
      <div className="flex flex-col md:flex-row gap-8">
        {switch m.posterPath {
        | Some(path) =>
          <img
            src={Tmdb.imageUrl(path)}
            alt={m.title}
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
          <h1 className="text-3xl font-bold text-gray-100 mb-1"> {Hjsx.string(m.title)} </h1>
          <div className="flex items-center gap-3 text-sm text-gray-400 mb-4">
            <span>
              {Hjsx.string(
                switch m.releaseDate {
                | Some(d) if d->String.length >= 4 => d->String.slice(~start=0, ~end=4)
                | _ => ""
                },
              )}
            </span>
            <span>
              {Hjsx.string(
                switch m.runtime {
                | Some(r) => `${Int.toString(r)} min`
                | None => ""
                },
              )}
            </span>
            <span className="text-gold-400">
              {Hjsx.string(`★ ${Float.toFixed(m.voteAverage, ~digits=1)}`)}
            </span>
          </div>
          <div className="text-sm text-gray-500 mb-4">
            {Hjsx.string(m.genres->Array.map(g => g.name)->Array.join(", "))}
          </div>
          {switch m.tagline {
          | Some(t) if t != "" => <p className="text-curio-400 italic mb-4"> {Hjsx.string(t)} </p>
          | _ => Hjsx.null
          }}
          <p className="text-gray-300 leading-relaxed mb-6">
            {Hjsx.string(m.overview->Option.getOr(""))}
          </p>
          {switch session {
          | Some(_) =>
            let pp = m.posterPath->Option.getOr("")
            <>
              <div className="flex items-center gap-3 mb-3">
                <FavoriteButton
                  tmdbId={m.id}
                  mediaType="movie"
                  title={m.title}
                  posterPath=pp
                  isFavorite
                  favoriteEndpoint
                />
                <WatchlistButton
                  tmdbId={m.id}
                  mediaType="movie"
                  title={m.title}
                  posterPath=pp
                  inWatchlist
                  wishlistEndpoint
                />
              </div>
              <StarRating
                tmdbId={m.id}
                mediaType="movie"
                title={m.title}
                posterPath=pp
                currentRating
                currentReview
                rateEndpoint
              />
            </>
          | None => Hjsx.null
          }}
        </div>
      </div>
    </div>
  | Some(Tv(t)) =>
    <div className="max-w-4xl mx-auto px-4 py-8">
      <div className="flex flex-col md:flex-row gap-8">
        {switch t.posterPath {
        | Some(path) =>
          <img
            src={Tmdb.imageUrl(path)}
            alt={t.name}
            className="w-64 rounded-lg shadow-lg ring-1 ring-gray-800 shrink-0"
          />
        | None =>
          <div
            className="w-64 h-96 rounded-lg bg-gray-800 flex items-center justify-center text-gray-500"
          >
            {Hjsx.string("No poster")}
          </div>
        }}
        <div className="flex-1">
          <h1 className="text-3xl font-bold text-gray-100 mb-1"> {Hjsx.string(t.name)} </h1>
          <div className="flex items-center gap-3 text-sm text-gray-400 mb-4">
            <span>
              {Hjsx.string(
                switch t.firstAirDate {
                | Some(d) if d->String.length >= 4 => d->String.slice(~start=0, ~end=4)
                | _ => ""
                },
              )}
            </span>
            <span>
              {Hjsx.string(
                switch t.numberOfSeasons {
                | Some(n) => `${Int.toString(n)} ${n == 1 ? "season" : "seasons"}`
                | None => ""
                },
              )}
            </span>
            <span className="text-gold-400">
              {Hjsx.string(`★ ${Float.toFixed(t.voteAverage, ~digits=1)}`)}
            </span>
          </div>
          <div className="text-sm text-gray-500 mb-4">
            {Hjsx.string(t.genres->Array.map(g => g.name)->Array.join(", "))}
          </div>
          {switch t.tagline {
          | Some(tl) if tl != "" =>
            <p className="text-curio-400 italic mb-4"> {Hjsx.string(tl)} </p>
          | _ => Hjsx.null
          }}
          <p className="text-gray-300 leading-relaxed mb-6"> {Hjsx.string(t.overview)} </p>
          {switch session {
          | Some(_) =>
            let pp = t.posterPath->Option.getOr("")
            <>
              <div className="flex items-center gap-3 mb-3">
                <FavoriteButton
                  tmdbId={t.id}
                  mediaType="tv"
                  title={t.name}
                  posterPath=pp
                  isFavorite
                  favoriteEndpoint
                />
                <WatchlistButton
                  tmdbId={t.id}
                  mediaType="tv"
                  title={t.name}
                  posterPath=pp
                  inWatchlist
                  wishlistEndpoint
                />
              </div>
              <StarRating
                tmdbId={t.id}
                mediaType="tv"
                title={t.name}
                posterPath=pp
                currentRating
                currentReview
                rateEndpoint
              />
            </>
          | None => Hjsx.null
          }}
        </div>
      </div>
    </div>
  }
}
