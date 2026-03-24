open Xote

@jsx.component
let make = (~handle: string) => {
  let content = Computed.make(() => {
    let wishlistItems = Signal.get(Wishlist.items)

    if Array.length(wishlistItems) == 0 {
      [
        <div class="flex justify-center py-12">
          <div class="text-gray-500"> {Component.text("Wishlist is empty")} </div>
        </div>,
      ]
    } else {
      [
        <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
          {Component.list(Wishlist.items, (item: Wishlist.wishlistRecord) => {
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
            </div>
          })}
        </div>,
      ]
    }
  })

  <div class="max-w-6xl mx-auto px-4 py-8">
    <h1 class="text-2xl font-bold text-gray-100 mb-6">
      {Component.text("@" ++ handle ++ "'s Wishlist")}
    </h1>
    {Component.signalFragment(content)}
  </div>
}
