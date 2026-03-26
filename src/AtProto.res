type agentOptions = {service: string}

module Service = {
  let bluesky = "https://public.api.bsky.app"
}

module Rkey: {
  type t = private string
  let schema: S.schema<t>
  let make: (~mediaType: string, ~tmdbId: int) => t
} = {
  @schema
  type t = string
  let make = (~mediaType, ~tmdbId) => `${mediaType}-${Int.toString(tmdbId)}`
}

module Repo = {
  type t
}

module Put = {
  module Input = {
    type t<'record, 'kind> = {
      repo: Handle.t,
      collection: 'kind,
      rkey: Rkey.t,
      record: 'record,
    }
    let schema = paramSchema =>
      S.schema(s => {
        repo: s.matches(Handle.schema),
        collection: s.matches(paramSchema),
        rkey: s.matches(Rkey.schema),
        record: s.matches(paramSchema),
      })
  }
}

module Delete = {
  module Input = {
    type t<'kind> = {
      repo: Handle.t,
      collection: 'kind,
      rkey: Rkey.t,
    }
    let schema = paramSchema =>
      S.schema(s => {
        repo: s.matches(Handle.schema),
        collection: s.matches(paramSchema),
        rkey: s.matches(Rkey.schema),
      })
  }
}

module List = {
  module Input = {
    type t<'kind> = {
      repo: Handle.t,
      collection: 'kind,
      limit: int,
    }

    let schema = paramSchema =>
      S.schema(s => {
        repo: s.matches(Handle.schema),
        collection: s.matches(paramSchema),
        limit: s.matches(S.int),
      })
  }

  module Record = {
    type t<'a> = {
      uri: string,
      value: 'a,
    }
    let schema = paramSchema =>
      S.schema(s => {
        uri: s.matches(S.string),
        value: s.matches(paramSchema),
      })
  }

  module Output = {
    type t<'record> = {records: array<Record.t<'record>>}
    let schema = paramSchema =>
      S.schema(s => {
        records: s.matches(S.array(Record.schema(paramSchema))),
      })
  }
}

module Response = {
  type t<'a> = {data: 'a}

  let schema = paramSchema =>
    S.schema(s => {
      data: s.matches(paramSchema),
    })
}

module type Collection = {
  type t
  type kind
  let kind: kind
  let schema: S.schema<t>

  let makeRkey: t => Rkey.t
}

// Access agent.com.atproto.repo via chained @get bindings
type atprotoApi = {repo: Repo.t}
type comApi = {atproto: atprotoApi}
type agent = private {com: comApi}

module type Operations = {
  type t

  let put: (agent, Handle.t, t) => promise<unit>
  let delete: (agent, Handle.t, Rkey.t) => promise<unit>
  let list: (agent, Handle.t, ~limit: int=?) => promise<Response.t<List.Output.t<t>>>
}

module MakeOperations = (Collection: Collection): (Operations with type t = Collection.t) => {
  type t = Collection.t
  type kind = Collection.kind

  @send
  external put: (Repo.t, Put.Input.t<JSON.t, kind>) => promise<unit> = "putRecord"

  let put = async (agent, did, t) => {
    await put(
      agent.com.atproto.repo,
      {
        repo: did,
        collection: Collection.kind,
        rkey: Collection.makeRkey(t),
        record: t->S.reverseConvertToJsonOrThrow(Collection.schema),
      },
    )
  }

  @send
  external delete: (Repo.t, Delete.Input.t<kind>) => promise<unit> = "deleteRecord"

  let delete = async (agent, did, rkey) => {
    await delete(
      agent.com.atproto.repo,
      {
        repo: did,
        collection: Collection.kind,
        rkey,
      },
    )
  }

  @send
  external list: (Repo.t, List.Input.t<kind>) => promise<JSON.t> = "listRecords"

  let list = async (agent, did, ~limit=100) => {
    let json = await list(
      agent.com.atproto.repo,
      {
        repo: did,
        collection: Collection.kind,
        limit,
      },
    )
    json->S.parseOrThrow(Response.schema(List.Output.schema(Collection.schema)))
  }
}

@module("@atproto/api") @new
external makeAgent: agentOptions => agent = "AtpAgent"

/** Add $type field to a JSON object for AT Protocol records */
let addType = (json, typ) => {
  switch json {
  | JSON.Object(dict) => Dict.set(dict, "$type", JSON.String(typ))
  | _ => Console.error2("Invalid JSON object", json)
  }
  json
}

module RatingCollection = {
  @unboxed @schema
  type kind = | @as("social.curio.rating") Rating

  let kind = Rating

  @schema
  type t = {
    tmdbId: int,
    mediaType: string,
    rating: int,
    review: @s.nullable option<string>,
    title: string,
    posterPath: string,
    createdAt?: @s.defaultWith(() => Spacetime.now()) Spacetime.t,
    \"$type"?: @s.default(Rating) kind,
  }

  let makeRkey = ({mediaType, tmdbId}) => Rkey.make(~mediaType, ~tmdbId)
}

module Rating = MakeOperations(RatingCollection)

module WatchlistCollection = {
  @schema
  type kind = | @as("social.curio.wishlistItem") Watchlist
  let kind = Watchlist

  @schema
  type t = {
    tmdbId: int,
    mediaType: string,
    title: string,
    posterPath: string,
    addedAt?: @s.defaultWith(() => Spacetime.now()) Spacetime.t,
    \"$type"?: @s.default(Watchlist) kind,
  }

  let makeRkey = ({mediaType, tmdbId}) => Rkey.make(~mediaType, ~tmdbId)
}

module Watchlist = MakeOperations(WatchlistCollection)

module FavoriteCollection = {
  @schema
  type kind = | @as("social.curio.favorite") Favorite
  let kind = Favorite

  @schema
  type t = {
    tmdbId: int,
    mediaType: string,
    title: string,
    posterPath: string,
    addedAt?: @s.defaultWith(() => Spacetime.now()) Spacetime.t,
    \"$type"?: @s.default(Favorite) kind,
  }

  let makeRkey = ({mediaType, tmdbId}) => Rkey.make(~mediaType, ~tmdbId)
}

module Favorite = MakeOperations(FavoriteCollection)
