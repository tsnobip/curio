@jsx.component
let make = (~searchEndpoint: Handlers.hxGet, ~recentReviews: array<ReviewStore.review>) => {
  <div className="max-w-6xl mx-auto px-4 py-8">
    <div className="mb-8">
      <div className="w-full max-w-2xl mx-auto">
        <input
          type_="search"
          name="q"
          placeholder="Search movies & TV shows..."
          className="w-full px-4 py-3 text-lg rounded-xl bg-gray-900 border border-gray-700 text-gray-100 placeholder-gray-500 focus:outline-none focus:border-curio-500 focus:ring-1 focus:ring-curio-500 transition-colors"
          hxGet={searchEndpoint}
          hxTrigger="input changed delay:500ms, search"
          hxTarget={Htmx.Target.make(CssSelector("#search-results"))}
          hxSwap={Htmx.Swap.make(InnerHTML)}
          hxIndicator={Htmx.Indicator.make(Selector("#search-indicator"))}
        />
      </div>
    </div>
    <div id="search-indicator" className="htmx-indicator flex justify-center py-4">
      <div className="text-gray-500"> {Hjsx.string("Searching...")} </div>
    </div>
    <div id="search-results">
      {if Array.length(recentReviews) > 0 {
        <div>
          <h2 className="text-lg font-semibold text-gray-100 mb-4">
            {Hjsx.string("Recent Reviews")}
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {recentReviews
            ->Array.map(review => <ReviewFeedCard review />)
            ->Hjsx.array}
          </div>
        </div>
      } else {
        <div className="flex justify-center py-12">
          <div className="text-gray-500">
            {Hjsx.string("Search for movies and TV shows to get started")}
          </div>
        </div>
      }}
    </div>
  </div>
}
