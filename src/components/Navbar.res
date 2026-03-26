module Avatar = {
  @jsx.component
  let make = (~session: Session.t, ~size="h-8 w-8 text-sm") => {
    switch session.avatar {
    | Some(url) =>
      <img
        src={url}
        alt={session.handle->Handle.toString}
        className={`rounded-full object-cover ${size}`}
      />
    | None =>
      let letter =
        session.displayName
        ->Option.getOr(session.handle->Handle.toString)
        ->String.get(0)
        ->Option.getOr("?")
        ->String.toUpperCase
      <div
        className={"rounded-full bg-curio-700 flex items-center justify-center font-medium text-curio-200 " ++
        size}
      >
        {Hjsx.string(letter)}
      </div>
    }
  }
}

let closeSidebar = "document.getElementById('sidebar').removeAttribute('data-open')"

module Sidebar = {
  @jsx.component
  let make = (~session: Session.t, ~logoutAction: Handlers.FormAction.t) => {
    let handle = session.handle->Handle.toString
    <div id="sidebar" className="group fixed inset-0 z-100 pointer-events-none">
      // Backdrop: fades in
      <div
        className="absolute inset-0 bg-black/50 opacity-0 group-data-open:opacity-100 transition-opacity duration-200 group-data-open:pointer-events-auto"
        onClick={closeSidebar}
      />
      // Panel: slides in from right
      <div
        className="absolute right-0 top-0 h-full w-72 bg-gray-900 border-l border-gray-800 p-6 flex flex-col pointer-events-auto translate-x-full group-data-open:translate-x-0 transition-transform duration-200"
      >
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center gap-3">
            <Avatar session />
            <div>
              {switch session.displayName {
              | Some(name) =>
                <div className="text-sm font-medium text-gray-100"> {Hjsx.string(name)} </div>
              | None => Hjsx.null
              }}
              <div className="text-xs text-gray-400"> {Hjsx.string(handle)} </div>
            </div>
          </div>
          <button
            className="text-gray-400 hover:text-gray-100 cursor-pointer rounded-full p-1 z-10"
            onClick={closeSidebar}
          >
            {Hjsx.string("✕")}
          </button>
        </div>
        <nav className="flex flex-col gap-1">
          <a
            href={`/${handle}/ratings`}
            className="px-3 py-2 rounded-lg text-gray-300 hover:text-gray-100 hover:bg-gray-800 transition-colors"
          >
            {Hjsx.string("My Ratings")}
          </a>
          <a
            href={`/${handle}/wishlist`}
            className="px-3 py-2 rounded-lg text-gray-300 hover:text-gray-100 hover:bg-gray-800 transition-colors"
          >
            {Hjsx.string("My Watchlist")}
          </a>
        </nav>
        <div className="mt-auto">
          <form action={logoutAction} method={POST}>
            <button
              type_="submit"
              className="w-full px-3 py-2 text-sm rounded-lg bg-gray-800 hover:bg-gray-700 text-gray-300 transition-colors cursor-pointer"
            >
              {Hjsx.string("Log out")}
            </button>
          </form>
        </div>
      </div>
    </div>
  }
}

let openSearch = "document.getElementById('search-overlay').dataset.open='true';document.getElementById('search-input').focus()"
let closeSearch = "document.getElementById('search-overlay').dataset.open='false';document.getElementById('search-input').value='';document.getElementById('search-results').innerHTML=''"

module SearchOverlay = {
  @jsx.component
  let make = (~searchEndpoint: Handlers.hxGet) => {
    <div
      id="search-overlay"
      className="group/search fixed inset-0 z-90 pointer-events-none"
      __rawProps={dict{"data-open": "false"->JSON.String}}
    >
      // Backdrop
      <div
        className="absolute inset-0 bg-black/60 opacity-0 group-data-[open=true]/search:opacity-100 transition-opacity duration-200 group-data-[open=true]/search:pointer-events-auto"
        onClick={closeSearch}
      />
      // Search panel
      <div
        className="absolute inset-x-0 top-0 max-h-[85vh] bg-gray-950 border-b border-gray-800 -translate-y-full group-data-[open=true]/search:translate-y-0 transition-transform duration-200 group-data-[open=true]/search:pointer-events-auto flex flex-col"
      >
        <div className="max-w-4xl w-full mx-auto px-4 flex flex-col min-h-0 max-h-[85vh]">
          <div className="sticky top-0 z-10 bg-gray-950 py-4 flex items-center gap-3">
            <input
              id="search-input"
              type_="search"
              name="q"
              placeholder="Search movies & TV shows..."
              className="flex-1 px-4 py-3 text-lg rounded-xl bg-gray-900 border
              border-gray-700 text-gray-100 placeholder-gray-500 focus:outline-none
              focus:border-curio-500 focus:ring-1 focus:ring-curio-500 transition-colors"
              hxGet={searchEndpoint}
              hxTrigger="input changed delay:500ms, search"
              hxTarget={Htmx.Target.make(CssSelector("#search-results"))}
              hxSwap={Htmx.Swap.make(InnerHTML)}
              hxIndicator={Htmx.Indicator.make(Selector("#search-indicator"))}
            />
            <button
              type_="button"
              onClick={closeSearch}
              className="text-gray-400 hover:text-gray-100 cursor-pointer text-xl px-2"
            >
              {Hjsx.string("✕")}
            </button>
          </div>
          <div className="overflow-y-auto min-h-0 pb-4">
            <div id="search-indicator" className="htmx-indicator flex justify-center py-4">
              <div className="text-gray-500"> {Hjsx.string("Searching...")} </div>
            </div>
            <div id="search-results" />
          </div>
        </div>
      </div>
    </div>
  }
}

@jsx.component
let make = (
  ~session: option<Session.t>,
  ~logoutAction: Handlers.FormAction.t,
  ~searchEndpoint: Handlers.hxGet,
) => {
  <>
    <nav className="border-b border-gray-800 bg-gray-950/80 backdrop-blur-sm sticky top-0 z-50">
      <div className="max-w-6xl mx-auto px-4 h-14 flex items-center justify-between">
        <a href="/" className="text-2xl font-[Bungee_Shade] text-curio-400 shrink-0">
          {Hjsx.string("Curio")}
        </a>
        <button
          type_="button"
          onClick={openSearch}
          className="flex-1 max-w-md mx-4 flex items-center gap-2 px-3 py-1.5 rounded-lg bg-gray-900 border border-gray-700 text-gray-500 hover:border-gray-600 hover:text-gray-400 transition-colors cursor-pointer"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
            fill="currentColor"
            className="w-4 h-4 shrink-0"
          >
            <path
              fillRule="evenodd"
              d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z"
              clipRule="evenodd"
            />
          </svg>
          <span className="text-sm line-clamp-1">
            {Hjsx.string("Search movies & TV shows...")}
          </span>
        </button>
        <div className="shrink-0">
          {switch session {
          | Some(s) =>
            <button
              className="cursor-pointer flex items-center"
              onClick="document.getElementById('sidebar').toggleAttribute('data-open')"
              title={s.handle->Handle.toString}
            >
              <Avatar session=s />
            </button>
          | None =>
            <a
              href="/login"
              className="px-3 py-1.5 text-sm rounded-lg bg-curio-600 hover:bg-curio-500 text-white font-medium transition-colors"
            >
              {Hjsx.string("Sign in")}
            </a>
          }}
        </div>
      </div>
    </nav>
    <SearchOverlay searchEndpoint />
    {switch session {
    | Some(s) => <Sidebar session=s logoutAction />
    | None => Hjsx.null
    }}
  </>
}
