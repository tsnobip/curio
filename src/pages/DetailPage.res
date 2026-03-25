@jsx.component
let make = async (
  ~mediaType: string,
  ~id: string,
  ~apiKey: string,
  ~session: option<Session.t>,
  ~rateEndpoint: Handlers.hxPost,
  ~wishlistEndpoint: Handlers.hxPost,
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

  let currentRating = switch session {
  | Some(s) =>
    try {
      let agent = await OAuth.restoreAgent(s.did)
      let ratings = await AtProto.loadRatings(agent, s.did)
      ratings
      ->Array.find(r => r.tmdbId == idNum && r.mediaType == mediaType)
      ->Option.map(r => r.rating)
      ->Option.getOr(0)
    } catch {
    | JsExn(e) =>
      Console.error2("Error loading ratings", e)
      0
    }
  | None => 0
  }

  let inWishlist = switch session {
  | Some(s) =>
    try {
      let agent = await OAuth.restoreAgent(s.did)
      let items = await AtProto.loadWishlist(agent, s.did)
      items->Array.some(w => w.tmdbId == idNum && w.mediaType == mediaType)
    } catch {
    | JsExn(e) =>
      Console.error2("Error loading wishlist", e)
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
            className="w-64 rounded-lg shadow-lg ring-1 ring-gray-800 flex-shrink-0"
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
                | Some(r) => Int.toString(r) ++ " min"
                | None => ""
                },
              )}
            </span>
            <span className="text-gold-400">
              {Hjsx.string("★ " ++ Float.toFixed(m.voteAverage, ~digits=1))}
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
            <div className="flex items-center gap-4">
              <StarRating
                tmdbId={m.id}
                mediaType="movie"
                title={m.title}
                posterPath={m.posterPath->Option.getOr("")}
                currentRating
                rateEndpoint
              />
              <WishlistButton
                tmdbId={m.id}
                mediaType="movie"
                title={m.title}
                posterPath={m.posterPath->Option.getOr("")}
                inWishlist
                wishlistEndpoint
              />
            </div>
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
            className="w-64 rounded-lg shadow-lg ring-1 ring-gray-800 flex-shrink-0"
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
                | Some(n) => Int.toString(n) ++ (n == 1 ? " season" : " seasons")
                | None => ""
                },
              )}
            </span>
            <span className="text-gold-400">
              {Hjsx.string("★ " ++ Float.toFixed(t.voteAverage, ~digits=1))}
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
            <div className="flex items-center gap-4">
              <StarRating
                tmdbId={t.id}
                mediaType="tv"
                title={t.name}
                posterPath={t.posterPath->Option.getOr("")}
                currentRating
                rateEndpoint
              />
              <WishlistButton
                tmdbId={t.id}
                mediaType="tv"
                title={t.name}
                posterPath={t.posterPath->Option.getOr("")}
                inWishlist
                wishlistEndpoint
              />
            </div>
          | None => Hjsx.null
          }}
        </div>
      </div>
    </div>
  }
}
