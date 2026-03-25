@jsx.component
let make = async (~handle: string, ~session: option<Session.t>) => {
  let items = try {
    let agent = switch session {
    | Some(s) if s.handle == handle => await OAuth.restoreAgent(s.did)
    | _ => AtProto.makeAgent({service: "https://public.api.bsky.app"})
    }
    let resp = await agent
    ->AtProto.repo
    ->AtProto.listRecords({
      repo: handle,
      collection: AtProto.wishlistCollection,
      limit: 100,
    })
    resp.data.records->Array.filterMap(entry =>
      try {
        Some(entry.value->S.parseOrThrow(AtProto.wishlistRecordSchema))
      } catch {
      | JsExn(e) =>
        Console.error2("Error parsing wishlist record", e)
        None
      }
    )
  } catch {
  | JsExn(e) =>
    Console.error2("Error loading wishlist for " ++ handle, e)
    []
  }

  <div className="max-w-6xl mx-auto px-4 py-8">
    <h1 className="text-2xl font-bold text-gray-100 mb-6">
      {Hjsx.string("@" ++ handle ++ "'s Wishlist")}
    </h1>
    {if Array.length(items) == 0 {
      <div className="flex justify-center py-12">
        <div className="text-gray-500"> {Hjsx.string("Wishlist is empty")} </div>
      </div>
    } else {
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
        {items
        ->Array.map((item: AtProto.wishlistRecord) => {
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
          </a>
        })
        ->Hjsx.array}
      </div>
    }}
  </div>
}
