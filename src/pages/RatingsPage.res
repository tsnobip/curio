@jsx.component
let make = async (~handle: string, ~session: option<Session.t>) => {
  let ratings = try {
    // Use authenticated agent if viewing own ratings, public API otherwise
    let agent = switch session {
    | Some(s) if s.handle == handle => await OAuth.restoreAgent(s.did)
    | _ => AtProto.makeAgent({service: "https://public.api.bsky.app"})
    }
    let resp = await agent
    ->AtProto.repo
    ->AtProto.listRecords({
      repo: handle,
      collection: AtProto.ratingCollection,
      limit: 100,
    })
    resp.data.records->Array.filterMap(entry =>
      try {
        Some(entry.value->S.parseOrThrow(AtProto.ratingRecordSchema))
      } catch {
      | JsExn(e) =>
        Console.error2("Error parsing rating record", e)
        None
      }
    )
  } catch {
  | JsExn(e) =>
    Console.error2("Error loading ratings for " ++ handle, e)
    []
  }

  <div className="max-w-6xl mx-auto px-4 py-8">
    <h1 className="text-2xl font-bold text-gray-100 mb-6">
      {Hjsx.string("@" ++ handle ++ "'s Ratings")}
    </h1>
    {if Array.length(ratings) == 0 {
      <div className="flex justify-center py-12">
        <div className="text-gray-500"> {Hjsx.string("No ratings yet")} </div>
      </div>
    } else {
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
        {ratings
        ->Array.map((item: AtProto.ratingRecord) => {
          let route = "/" ++ item.mediaType ++ "/" ++ Int.toString(item.tmdbId)
          let posterContent = if item.posterPath != "" {
            <img
              src={Tmdb.imageUrl(item.posterPath)}
              alt={item.title}
              className="w-full h-full object-cover"
            />
          } else {
            <div
              className="w-full h-full bg-gray-800 flex items-center justify-center text-gray-500 text-sm"
            >
              {Hjsx.string("No poster")}
            </div>
          }

          let stars = Array.fromInitializer(~length=5, i =>
            if i < item.rating {
              "\u2605"
            } else {
              "\u2606"
            }
          )->Array.join("")

          <a href={route} className="group cursor-pointer block">
            <div
              className="aspect-[2/3] rounded-lg overflow-hidden mb-2 ring-1 ring-gray-800 group-hover:ring-curio-500 transition-all"
            >
              {posterContent}
            </div>
            <h3
              className="text-sm font-medium text-gray-200 truncate group-hover:text-curio-400 transition-colors"
            >
              {Hjsx.string(item.title)}
            </h3>
            <span className="text-xs text-gold-400"> {Hjsx.string(stars)} </span>
          </a>
        })
        ->Hjsx.array}
      </div>
    }}
  </div>
}
