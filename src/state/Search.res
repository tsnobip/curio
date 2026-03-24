open Xote

let query = Signal.make("")
let results: Signal.t<array<Tmdb.searchResult>> = Signal.make([])
let loading = Signal.make(false)

let search = async q =>
  switch q->String.trim {
  | "" => Signal.set(results, [])
  | _ =>
    Signal.set(loading, true)
    try {
      let r = await Tmdb.searchMulti(q)
      Signal.set(results, r)
    } catch {
    | e =>
      Console.error2("Error searching", e)
      Signal.set(results, [])
    }
    Signal.set(loading, false)
  }

Effect.run(() => {
  let query = Signal.get(query)

  let timeoutId = setTimeout(~handler=() => {
    search(query)->Promise.ignore
  }, ~timeout=500)
  // Clean up timeout when draft changes again
  Some(
    () => {
      clearTimeout(timeoutId)
    },
  )
})->ignore
