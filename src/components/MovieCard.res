open Xote

@jsx.component
let make = (~result) => {
  let title = Tmdb.displayTitle(result)
  let year = Tmdb.displayYear(result)
  let route = "/" ++ result.mediaType ++ "/" ++ Int.toString(result.id)

  let posterContent = switch result.posterPath {
  | Some(path) => <img src={Tmdb.imageUrl(path)} alt={title} class="w-full h-full object-cover" />
  | None =>
    <div class="w-full h-full bg-gray-800 flex items-center justify-center text-gray-500 text-sm">
      {Component.text("No poster")}
    </div>
  }

  <div class="group cursor-pointer" onClick={_evt => Router.push(route, ())}>
    <div
      class="aspect-2/3 rounded-lg overflow-hidden mb-2 ring-1 ring-gray-800 group-hover:ring-curio-500 transition-all"
    >
      {posterContent}
    </div>
    <h3
      class="text-sm font-medium text-gray-200 truncate group-hover:text-curio-400 transition-colors"
    >
      {Component.text(title)}
    </h3>
    <div class="flex items-center gap-2 mt-0.5">
      <span class="text-xs text-gray-500"> {Component.text(year)} </span>
      <span class="text-xs text-gold-400">
        {switch result.voteAverage {
        | Some(rating) => Component.text("\u2605 " ++ Float.toFixed(rating, ~digits=1))
        | None => Component.text("No rating yet")
        }}
      </span>
    </div>
  </div>
}
