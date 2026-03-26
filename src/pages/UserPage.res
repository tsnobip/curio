module ProfileHeader = {
  @jsx.component
  let make = (~handle: Handle.t, ~avatar: option<string>, ~displayName: option<string>) => {
    <div className="flex items-center gap-4 mb-8">
      <ReviewFeedCard.Avatar handle avatar size="h-16 w-16 text-2xl" />
      <div>
        {switch displayName {
        | Some(name) if name != "" =>
          <h1 className="text-2xl font-bold text-gray-100"> {Hjsx.string(name)} </h1>
        | _ => Hjsx.null
        }}
        <div className="text-gray-400"> {Hjsx.string(handle->Handle.toString)} </div>
      </div>
    </div>
  }
}

module MediaGrid = {
  @jsx.component
  let make = (~title: string, ~showAllHref: string, ~children: Jsx.element) => {
    <div>
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-lg font-semibold text-gray-100"> {Hjsx.string(title)} </h2>
        <a
          href={showAllHref}
          className="text-sm text-curio-400 hover:text-curio-300 transition-colors"
        >
          {Hjsx.string("Show all →")}
        </a>
      </div>
      {children}
    </div>
  }
}

module PosterCard = {
  @jsx.component
  let make = (~href: string, ~posterPath: string, ~title: string, ~subtitle: option<string>=?) => {
    <a href className="group cursor-pointer block">
      <div
        className="aspect-2/3 rounded-lg overflow-hidden mb-2 ring-1 ring-gray-800 group-hover:ring-curio-500 transition-all"
      >
        {if posterPath != "" {
          <img src={Tmdb.imageUrl(posterPath)} alt={title} className="w-full h-full object-cover" />
        } else {
          <div
            className="w-full h-full bg-gray-800 flex items-center justify-center text-gray-500 text-sm"
          >
            {Hjsx.string("No poster")}
          </div>
        }}
      </div>
      <h3
        className="text-sm font-medium text-gray-200 truncate group-hover:text-curio-400 transition-colors"
      >
        {Hjsx.string(title)}
      </h3>
      {switch subtitle {
      | Some(s) => <span className="text-xs text-gold-400"> {Hjsx.string(s)} </span>
      | None => Hjsx.null
      }}
    </a>
  }
}

@jsx.component
let make = async (~handle: Handle.t, ~session: option<Session.t>) => {
  // Fetch profile
  let agent = switch session {
  | Some(s) if s.handle == handle => await OAuth.restoreAgent(s.did)
  | _ => AtProto.makeAgent({service: AtProto.Service.bluesky})
  }

  let (displayName, avatar) = try {
    let profile = await OAuth.getProfileFull(agent, {actor: handle})
    (profile.data.displayName, profile.data.avatar)
  } catch {
  | JsExn(e) =>
    Console.error2("Error loading profile", e)
    (None, None)
  }

  // Latest ratings (try local store first, fallback to ATProto)
  let localReviews = ReviewStore.getForUser(~did=handle, ~limit=3)
  let ratings = if Array.length(localReviews) > 0 {
    localReviews->Array.map(r => {
      let rating: AtProto.RatingCollection.t = {
        tmdbId: r.tmdbId,
        mediaType: r.mediaType,
        rating: r.rating,
        review: r.review,
        title: r.title,
        posterPath: r.posterPath,
      }
      rating
    })
  } else {
    try {
      let resp = await AtProto.Rating.list(agent, handle, ~limit=3)
      resp.data.records->Array.map(r => r.value)
    } catch {
    | JsExn(e) =>
      Console.error2("Error loading ratings", e)
      []
    }
  }

  // Latest watchlist items
  let watchlist = try {
    let resp = await AtProto.Watchlist.list(agent, handle, ~limit=3)
    resp.data.records->Array.map(r => r.value)
  } catch {
  | JsExn(e) =>
    Console.error2("Error loading watchlist", e)
    []
  }

  <div className="max-w-4xl mx-auto px-4 py-8">
    <ProfileHeader handle avatar displayName />
    <div className="space-y-10">
      {if Array.length(ratings) > 0 {
        <MediaGrid title="Ratings" showAllHref={`${handle->Handle.toString}/ratings`}>
          <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-4">
            {ratings
            ->Array.map(item => {
              <PosterCard
                href={`/${item.mediaType}/${Int.toString(item.tmdbId)}`}
                posterPath={item.posterPath}
                title={item.title}
                subtitle={`★ ${Int.toString(item.rating)}/10`}
              />
            })
            ->Hjsx.array}
          </div>
        </MediaGrid>
      } else {
        Hjsx.null
      }}
      {if Array.length(watchlist) > 0 {
        <MediaGrid title="Watchlist" showAllHref={`${handle->Handle.toString}/wishlist`}>
          <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-4">
            {watchlist
            ->Array.map(item => {
              <PosterCard
                href={`/${item.mediaType}/${Int.toString(item.tmdbId)}`}
                posterPath={item.posterPath}
                title={item.title}
              />
            })
            ->Hjsx.array}
          </div>
        </MediaGrid>
      } else {
        Hjsx.null
      }}
    </div>
  </div>
}
