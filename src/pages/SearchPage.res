open Xote

@jsx.component
let make = () => {
  let content = Computed.make(() => {
    let isLoading = Signal.get(Search.loading)
    let searchResults = Signal.get(Search.results)
    let query = Signal.get(Search.query)

    if isLoading {
      [
        <div class="flex justify-center py-12">
          <div class="text-gray-500"> {Component.text("Searching...")} </div>
        </div>,
      ]
    } else if Array.length(searchResults) > 0 {
      [
        <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
          {Component.list(Search.results, result => <MovieCard result />)}
        </div>,
      ]
    } else if query->String.trim != "" {
      [
        <div class="flex justify-center py-12">
          <div class="text-gray-500"> {Component.text("No results found")} </div>
        </div>,
      ]
    } else {
      [
        <div class="flex justify-center py-12">
          <div class="text-gray-500">
            {Component.text("Search for movies and TV shows to get started")}
          </div>
        </div>,
      ]
    }
  })

  <div class="max-w-6xl mx-auto px-4 py-8">
    <div class="mb-8">
      <SearchBar />
    </div>
    {Component.signalFragment(content)}
  </div>
}
