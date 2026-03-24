open Xote

@jsx.component
let make = (~handle: string) => {
  let content = Computed.make(() => {
    let ratingsList = Signal.get(Ratings.ratings)

    if Array.length(ratingsList) == 0 {
      [
        <div class="flex justify-center py-12">
          <div class="text-gray-500"> {Component.text("No ratings yet")} </div>
        </div>,
      ]
    } else {
      [
        <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
          {Component.list(Ratings.ratings, (item: Ratings.ratingRecord) => {
            let route = "/" ++ item.mediaType ++ "/" ++ Int.toString(item.tmdbId)
            let posterContent = if item.posterPath != "" {
              <img src={Tmdb.imageUrl(item.posterPath)} alt={item.title} class="w-full h-full object-cover" />
            } else {
              <div
                class="w-full h-full bg-gray-800 flex items-center justify-center text-gray-500 text-sm"
              >
                {Component.text("No poster")}
              </div>
            }

            let stars = Array.fromInitializer(
              ~length=5,
              i =>
                if i < item.rating {
                  "\u2605"
                } else {
                  "\u2606"
                },
            )->Array.join("")

            <div class="group cursor-pointer" onClick={_evt => Router.push(route, ())}>
              <div
                class="aspect-[2/3] rounded-lg overflow-hidden mb-2 ring-1 ring-gray-800 group-hover:ring-curio-500 transition-all"
              >
                {posterContent}
              </div>
              <h3
                class="text-sm font-medium text-gray-200 truncate group-hover:text-curio-400 transition-colors"
              >
                {Component.text(item.title)}
              </h3>
              <span class="text-xs text-gold-400"> {Component.text(stars)} </span>
            </div>
          })}
        </div>,
      ]
    }
  })

  <div class="max-w-6xl mx-auto px-4 py-8">
    <h1 class="text-2xl font-bold text-gray-100 mb-6">
      {Component.text("@" ++ handle ++ "'s Ratings")}
    </h1>
    {Component.signalFragment(content)}
  </div>
}
