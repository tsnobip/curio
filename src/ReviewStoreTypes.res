@schema
type review = {
  mediaKey: string,
  did: Handle.t,
  rating: int,
  review: @s.nullable option<string>,
  title: string,
  @as("poster_path") posterPath: string,
  @as("media_type") mediaType: string,
  @as("tmdb_id") tmdbId: int,
  handle: Handle.t,
  avatar: @s.nullable option<string>,
  @as("created_at") createdAt: Spacetime.t,
}

module type Impl = {
  let put: review => promise<unit>
  let delete: (~mediaKey: string, ~did: Handle.t) => promise<unit>
  let getForMedia: (~mediaKey: string, ~excludeDid: Handle.t=?) => promise<array<review>>
  let getRecent: (~limit: int=?) => promise<array<review>>
  let getForUser: (~did: Handle.t, ~limit: int=?) => promise<array<review>>
}

let mediaKey = (~mediaType, ~tmdbId) => `${mediaType}#${Int.toString(tmdbId)}`
