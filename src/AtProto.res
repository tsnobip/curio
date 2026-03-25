type agent

type agentOptions = {service: string}

@module("@atproto/api") @new
external makeAgent: agentOptions => agent = "AtpAgent"

type putRecordInput<'a> = {
  repo: string,
  collection: string,
  rkey: string,
  record: 'a,
}

type deleteRecordInput = {
  repo: string,
  collection: string,
  rkey: string,
}

type listRecordsInput = {
  repo: string,
  collection: string,
  limit: int,
}

type recordEntry = {
  uri: string,
  value: JSON.t,
}

type listRecordsOutput = {records: array<recordEntry>}

type apiResponse<'a> = {data: 'a}

// Access agent.com.atproto.repo via chained @get bindings
type repoApi
type atprotoApi = {repo: repoApi}
type comApi = {atproto: atprotoApi}
@get external getCom: agent => comApi = "com"

@send
external putRecord: (repoApi, putRecordInput<'a>) => promise<apiResponse<{..}>> = "putRecord"

@send
external deleteRecord: (repoApi, deleteRecordInput) => promise<apiResponse<{..}>> = "deleteRecord"

@send
external listRecords: (repoApi, listRecordsInput) => promise<apiResponse<listRecordsOutput>> =
  "listRecords"

let repo = (agent: agent) => getCom(agent).atproto.repo

/** Add $type field to a JSON object for AT Protocol records */
let addType = (json, typ) => {
  switch json {
  | JSON.Object(dict) => Dict.set(dict, "$type", JSON.String(typ))
  | _ => Console.error2("Invalid JSON object", json)
  }
  json
}

let ratingCollection = "social.curio.rating"
let wishlistCollection = "social.curio.wishlistItem"

let rkey = (mediaType, tmdbId) => mediaType ++ "-" ++ Int.toString(tmdbId)

@schema
type ratingRecord = {
  tmdbId: int,
  mediaType: string,
  rating: int,
  title: string,
  posterPath: string,
  createdAt: string,
}

@schema
type wishlistRecord = {
  tmdbId: int,
  mediaType: string,
  title: string,
  posterPath: string,
  addedAt: string,
}

let putRating = async (agent, did, tmdbId, mediaType, rating, title, posterPath) => {
  let record = {
    tmdbId,
    mediaType,
    rating,
    title,
    posterPath,
    createdAt: Date.make()->Date.toISOString,
  }
  await agent
  ->repo
  ->putRecord({
    repo: did,
    collection: ratingCollection,
    rkey: rkey(mediaType, tmdbId),
    record: record->S.reverseConvertToJsonOrThrow(ratingRecordSchema)->addType(ratingCollection),
  })
}

let deleteRating = async (agent, did, tmdbId, mediaType) => {
  await agent
  ->repo
  ->deleteRecord({
    repo: did,
    collection: ratingCollection,
    rkey: rkey(mediaType, tmdbId),
  })
}

let putWishlistItem = async (agent, did, tmdbId, mediaType, title, posterPath) => {
  let record = {
    tmdbId,
    mediaType,
    title,
    posterPath,
    addedAt: Date.make()->Date.toISOString,
  }
  await agent
  ->repo
  ->putRecord({
    repo: did,
    collection: wishlistCollection,
    rkey: rkey(mediaType, tmdbId),
    record: record
    ->S.reverseConvertToJsonOrThrow(wishlistRecordSchema)
    ->addType(wishlistCollection),
  })
}

let deleteWishlistItem = async (agent, did, tmdbId, mediaType) => {
  await agent
  ->repo
  ->deleteRecord({
    repo: did,
    collection: wishlistCollection,
    rkey: rkey(mediaType, tmdbId),
  })
}

let loadRatings = async (agent, did) => {
  try {
    let resp = await agent->repo->listRecords({repo: did, collection: ratingCollection, limit: 100})
    resp.data.records->Array.filterMap(entry =>
      try {
        Some(entry.value->S.parseOrThrow(ratingRecordSchema))
      } catch {
      | JsExn(e) =>
        Console.error2("Error parsing rating record", e)
        None
      }
    )
  } catch {
  | JsExn(e) =>
    Console.error2("Error loading ratings", e)
    []
  }
}

let loadWishlist = async (agent, did) => {
  try {
    let resp = await agent
    ->repo
    ->listRecords({repo: did, collection: wishlistCollection, limit: 100})
    resp.data.records->Array.filterMap(entry =>
      try {
        Some(entry.value->S.parseOrThrow(wishlistRecordSchema))
      } catch {
      | JsExn(e) =>
        Console.error2("Error parsing wishlist record", e)
        None
      }
    )
  } catch {
  | JsExn(e) =>
    Console.error2("Error loading wishlist", e)
    []
  }
}
