open Xote

@jsx.component
let make = () => {
  let onInput = evt => {
    let value = Util.inputValue(evt)
    Signal.set(Search.query, value)
  }

  <div class="w-full max-w-2xl mx-auto">
    <input
      type_="text"
      placeholder="Search movies & TV shows..."
      class="w-full px-4 py-3 text-lg rounded-xl bg-gray-900 border border-gray-700 text-gray-100 placeholder-gray-500 focus:outline-none focus:border-curio-500 focus:ring-1 focus:ring-curio-500 transition-colors"
      onInput={onInput}
    />
  </div>
}
