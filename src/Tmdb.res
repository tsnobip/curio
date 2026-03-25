let baseUrl = "https://api.themoviedb.org/3"

let imageUrl = posterPath => "https://image.tmdb.org/t/p/w500" ++ posterPath

@schema
type searchResult = {
  id: int,
  @as("media_type") mediaType: string,
  title: @s.nullable option<string>,
  name: @s.nullable option<string>,
  @as("poster_path") posterPath: @s.nullable option<string>,
  @as("release_date") releaseDate: @s.nullable option<string>,
  @as("first_air_date") firstAirDate: @s.nullable option<string>,
  overview: @s.nullable option<string>,
  @as("vote_average") voteAverage: @s.nullable option<float>,
}

@schema
type searchResponse = {
  results: array<searchResult>,
}

@schema
type genre = {
  id: int,
  name: string,
}

@schema
type movieDetail = {
  id: int,
  title: string,
  @as("poster_path") posterPath: @s.nullable option<string>,
  @as("backdrop_path") backdropPath: @s.nullable option<string>,
  @as("release_date") releaseDate: @s.nullable option<string>,
  overview: @s.nullable option<string>,
  @as("vote_average") voteAverage: float,
  runtime: @s.nullable option<int>,
  genres: array<genre>,
  tagline: @s.nullable option<string>,
}

@schema
type tvDetail = {
  id: int,
  name: string,
  @as("poster_path") posterPath: @s.nullable option<string>,
  @as("backdrop_path") backdropPath: @s.nullable option<string>,
  @as("first_air_date") firstAirDate: @s.nullable option<string>,
  overview: string,
  @as("vote_average") voteAverage: float,
  @as("number_of_seasons") numberOfSeasons: @s.nullable option<int>,
  genres: array<genre>,
  tagline: @s.nullable option<string>,
}

type mediaDetail =
  | Movie(movieDetail)
  | Tv(tvDetail)

let fetchJson = async (apiKey, url) => {
  let headers = Dict.fromArray([
    ("Authorization", "Bearer " ++ apiKey),
    ("Content-Type", "application/json"),
  ])
  let resp = await fetch(url, ~init={headers: FromDict(headers)})
  await resp->Response.json
}

let searchMulti = async (apiKey, query) => {
  let url = baseUrl ++ "/search/multi?query=" ++ encodeURIComponent(query) ++ "&include_adult=false"
  let json = await fetchJson(apiKey, url)
  let response = json->S.parseOrThrow(searchResponseSchema)
  response.results->Array.filter(r => r.mediaType == "movie" || r.mediaType == "tv")
}

let fetchMovie = async (apiKey, id) => {
  let url = baseUrl ++ "/movie/" ++ Int.toString(id)
  let json = await fetchJson(apiKey, url)
  Movie(json->S.parseOrThrow(movieDetailSchema))
}

let fetchTv = async (apiKey, id) => {
  let url = baseUrl ++ "/tv/" ++ Int.toString(id)
  let json = await fetchJson(apiKey, url)
  Tv(json->S.parseOrThrow(tvDetailSchema))
}

let displayTitle = (result: searchResult) =>
  switch result.title {
  | Some(t) => t
  | None =>
    switch result.name {
    | Some(n) => n
    | None => "Unknown"
    }
  }

let displayYear = (result: searchResult) => {
  let date = switch result.releaseDate {
  | Some("") | None => result.firstAirDate
  | Some(d) => Some(d)
  }
  switch date {
  | Some(d) if d->String.length >= 4 => d->String.slice(~start=0, ~end=4)
  | _ => ""
  }
}
