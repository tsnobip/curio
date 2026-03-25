module Avatar = {
  @jsx.component
  let make = (~session: Session.t, ~size="h-8 w-8 text-sm") => {
    switch session.avatar {
    | Some(url) =>
      <img src={url} alt={session.handle} className={"rounded-full object-cover " ++ size} />
    | None =>
      let letter =
        session.displayName
        ->Option.getOr(session.handle)
        ->String.get(0)
        ->Option.map(String.make)
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
              <div className="text-xs text-gray-400"> {Hjsx.string("@" ++ session.handle)} </div>
            </div>
          </div>
          <button
            className="text-gray-400 hover:text-gray-100 cursor-pointer" onClick={closeSidebar}
          >
            {Hjsx.string("\u2715")}
          </button>
        </div>
        <nav className="flex flex-col gap-1">
          <a
            href={"/@" ++ session.handle ++ "/ratings"}
            className="px-3 py-2 rounded-lg text-gray-300 hover:text-gray-100 hover:bg-gray-800 transition-colors"
          >
            {Hjsx.string("My Ratings")}
          </a>
          <a
            href={"/@" ++ session.handle ++ "/wishlist"}
            className="px-3 py-2 rounded-lg text-gray-300 hover:text-gray-100 hover:bg-gray-800 transition-colors"
          >
            {Hjsx.string("My Wishlist")}
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

@jsx.component
let make = (~session: option<Session.t>, ~logoutAction: Handlers.FormAction.t) => {
  <>
    <nav className="border-b border-gray-800 bg-gray-950/80 backdrop-blur-sm sticky top-0 z-50">
      <div className="max-w-6xl mx-auto px-4 h-14 flex items-center justify-between">
        <a href="/" className="text-xl font-bold text-curio-400 tracking-tight">
          {Hjsx.string("Curio")}
        </a>
        {switch session {
        | Some(s) =>
          <button
            className="cursor-pointer flex items-center"
            onClick="document.getElementById('sidebar').toggleAttribute('data-open')"
            title={"@" ++ s.handle}
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
    </nav>
    {switch session {
    | Some(s) => <Sidebar session=s logoutAction />
    | None => Hjsx.null
    }}
  </>
}
