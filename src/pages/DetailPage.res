open Xote

@jsx.component
let make = (~mediaType, ~id) => {
  let detail: Signal.t<option<Tmdb.mediaDetail>> = Signal.make(None)
  let loading = Signal.make(true)

  let idNum = Int.fromString(id)->Option.getOr(0)

  let _ = Effect.run(() => {
    let fetchDetail = async () => {
      Signal.set(loading, true)
      try {
        let d = if mediaType == "tv" {
          await Tmdb.fetchTv(idNum)
        } else {
          await Tmdb.fetchMovie(idNum)
        }
        Signal.set(detail, Some(d))
      } catch {
      | _ => ()
      }
      Signal.set(loading, false)
    }
    fetchDetail()->ignore
    None
  })

  let content = Computed.make(() => {
    let isLoading = Signal.get(loading)
    let d = Signal.get(detail)

    if isLoading {
      [
        <div class="flex justify-center py-20">
          <div class="text-gray-500"> {Component.text("Loading...")} </div>
        </div>,
      ]
    } else {
      switch d {
      | None => [
          <div class="flex justify-center py-20">
            <div class="text-gray-500"> {Component.text("Not found")} </div>
          </div>,
        ]
      | Some(Movie(m)) => {
          let poster = switch m.posterPath {
          | Some(path) =>
            <img
              src={Tmdb.imageUrl(path)}
              alt={m.title}
              class="w-64 rounded-lg shadow-lg ring-1 ring-gray-800 flex-shrink-0"
            />
          | None =>
            <div
              class="w-64 h-96 rounded-lg bg-gray-800 flex items-center justify-center text-gray-500"
            >
              {Component.text("No poster")}
            </div>
          }

          let year = switch m.releaseDate {
          | Some(d) if d->String.length >= 4 => d->String.slice(~start=0, ~end=4)
          | _ => ""
          }

          let genres = m.genres->Array.map(g => g.name)->Array.join(", ")

          let runtime = switch m.runtime {
          | Some(r) => Int.toString(r) ++ " min"
          | None => ""
          }

          let tagline = switch m.tagline {
          | Some(t) if t != "" => <p class="text-curio-400 italic mb-4"> {Component.text(t)} </p>
          | _ => Component.text("")
          }

          [
            <div class="flex flex-col md:flex-row gap-8">
              {poster}
              <div class="flex-1">
                <h1 class="text-3xl font-bold text-gray-100 mb-1"> {Component.text(m.title)} </h1>
                <div class="flex items-center gap-3 text-sm text-gray-400 mb-4">
                  <span> {Component.text(year)} </span>
                  <span> {Component.text(runtime)} </span>
                  <span class="text-gold-400">
                    {Component.text("\u2605 " ++ Float.toFixed(m.voteAverage, ~digits=1))}
                  </span>
                </div>
                <div class="text-sm text-gray-500 mb-4"> {Component.text(genres)} </div>
                {tagline}
                <p class="text-gray-300 leading-relaxed mb-6">
                  {Component.text(m.overview->Option.getOr(""))}
                </p>
                <div class="flex items-center gap-4">
                  <StarRating
                    tmdbId={m.id} mediaType="movie" title={m.title} posterPath={m.posterPath}
                  />
                  <WishlistButton
                    tmdbId={m.id} mediaType="movie" title={m.title} posterPath={m.posterPath}
                  />
                </div>
              </div>
            </div>,
          ]
        }
      | Some(Tv(t)) => {
          let poster = switch t.posterPath {
          | Some(path) =>
            <img
              src={Tmdb.imageUrl(path)}
              alt={t.name}
              class="w-64 rounded-lg shadow-lg ring-1 ring-gray-800 flex-shrink-0"
            />
          | None =>
            <div
              class="w-64 h-96 rounded-lg bg-gray-800 flex items-center justify-center text-gray-500"
            >
              {Component.text("No poster")}
            </div>
          }

          let year = switch t.firstAirDate {
          | Some(d) if d->String.length >= 4 => d->String.slice(~start=0, ~end=4)
          | _ => ""
          }

          let genres = t.genres->Array.map(g => g.name)->Array.join(", ")

          let seasons = switch t.numberOfSeasons {
          | Some(n) => Int.toString(n) ++ (n == 1 ? " season" : " seasons")
          | None => ""
          }

          let tagline = switch t.tagline {
          | Some(tl) if tl != "" => <p class="text-curio-400 italic mb-4"> {Component.text(tl)} </p>
          | _ => Component.text("")
          }

          [
            <div class="flex flex-col md:flex-row gap-8">
              {poster}
              <div class="flex-1">
                <h1 class="text-3xl font-bold text-gray-100 mb-1"> {Component.text(t.name)} </h1>
                <div class="flex items-center gap-3 text-sm text-gray-400 mb-4">
                  <span> {Component.text(year)} </span>
                  <span> {Component.text(seasons)} </span>
                  <span class="text-gold-400">
                    {Component.text("\u2605 " ++ Float.toFixed(t.voteAverage, ~digits=1))}
                  </span>
                </div>
                <div class="text-sm text-gray-500 mb-4"> {Component.text(genres)} </div>
                {tagline}
                <p class="text-gray-300 leading-relaxed mb-6"> {Component.text(t.overview)} </p>
                <div class="flex items-center gap-4">
                  <StarRating
                    tmdbId={t.id} mediaType="tv" title={t.name} posterPath={t.posterPath}
                  />
                  <WishlistButton
                    tmdbId={t.id} mediaType="tv" title={t.name} posterPath={t.posterPath}
                  />
                </div>
              </div>
            </div>,
          ]
        }
      }
    }
  })

  <div class="max-w-4xl mx-auto px-4 py-8"> {Component.signalFragment(content)} </div>
}
