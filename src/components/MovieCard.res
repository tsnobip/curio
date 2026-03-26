@jsx.component
let make = (~result: Tmdb.searchResult) => {
  let title = Tmdb.displayTitle(result)
  let year = Tmdb.displayYear(result)
  let route = `/${result.mediaType}/${Int.toString(result.id)}`

  let posterContent = switch result.posterPath {
  | Some(path) =>
    <img src={Tmdb.imageUrl(path)} alt={title} className="w-full h-full object-cover" />
  | None =>
    <div
      className="w-full h-full bg-gray-800 flex items-center justify-center text-gray-500 text-sm"
    >
      {Hjsx.string("No poster")}
    </div>
  }

  <a href={route} className="group cursor-pointer block">
    <div
      className="aspect-2/3 rounded-lg overflow-hidden mb-2 ring-1 ring-gray-800 group-hover:ring-curio-500 transition-all"
    >
      {posterContent}
    </div>
    <h3
      className="text-sm font-medium text-gray-200 truncate group-hover:text-curio-400 transition-colors"
    >
      {Hjsx.string(title)}
    </h3>
    <div className="flex items-center gap-2 mt-0.5">
      <span className="text-xs text-gray-500"> {Hjsx.string(year)} </span>
      <span className="text-xs text-gold-400">
        {switch result.voteAverage {
        | Some(rating) => Hjsx.string(`★ ${Float.toFixed(rating, ~digits=1)}`)
        | None => Hjsx.string("No rating yet")
        }}
      </span>
    </div>
  </a>
}
