@jsx.component
let make = (~loginWithHandleAction: Handlers.FormAction.t, ~error: option<string>) => {
  <div className="max-w-sm mx-auto px-4 py-16">
    <div className="text-center mb-8">
      <h1 className="text-3xl font-bold text-curio-400 mb-2"> {Hjsx.string("Curio")} </h1>
      <p className="text-gray-400"> {Hjsx.string("Sign in to rate and save movies")} </p>
    </div>
    {switch error {
    | Some(msg) =>
      <div
        className="mb-6 px-4 py-3 rounded-lg bg-red-900/30 border border-red-800 text-red-300 text-sm"
      >
        {Hjsx.string(msg)}
      </div>
    | None => Hjsx.null
    }}
    <form action={loginWithHandleAction} method={POST} className="space-y-4">
      <div>
        <label htmlFor="handle" className="block text-sm font-medium text-gray-300 mb-1">
          {Hjsx.string("Your handle")}
        </label>
        <input
          type_="text"
          id="handle"
          name="handle"
          placeholder="alice.bsky.social"
          required=true
          autoFocus=true
          className="w-full px-4 py-3 rounded-lg bg-gray-900 border border-gray-700 text-gray-100 placeholder-gray-500 focus:outline-none focus:border-curio-500 focus:ring-1 focus:ring-curio-500 transition-colors"
        />
        <p className="mt-1.5 text-xs text-gray-500">
          {Hjsx.string("Works with Bluesky and any AT Protocol service")}
        </p>
      </div>
      <button
        type_="submit"
        className="w-full px-4 py-3 rounded-lg bg-curio-600 hover:bg-curio-500 text-white font-medium transition-colors"
      >
        {Hjsx.string("Sign in")}
      </button>
    </form>
  </div>
}
