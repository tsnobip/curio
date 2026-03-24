open Xote

@schema
type wishlistRecord = {
  tmdbId: int,
  mediaType: string,
  title: string,
  posterPath: string,
  addedAt: string,
}

let items: Signal.t<array<wishlistRecord>> = Signal.make([])

let collection = "social.curio.wishlistItem"

let rkey = (mediaType, tmdbId) =>
  mediaType ++ "-" ++ Int.toString(tmdbId)

let add = async (~tmdbId, ~mediaType, ~title, ~posterPath) => {
  switch Signal.get(Auth.session) {
  | Some({did, agent}) =>
    let record = {
      tmdbId,
      mediaType,
      title,
      posterPath: posterPath->Option.getOr(""),
      addedAt: Date.make()->Date.toISOString,
    }
    try {
      let _ = await AtProto.putRecord(
        agent,
        "com.atproto.repo.putRecord",
        {
          repo: did,
          collection,
          rkey: rkey(mediaType, tmdbId),
          record: record->S.reverseConvertToJsonOrThrow(wishlistRecordSchema)->Util.addType(collection),
        },
      )
      Signal.update(items, ws =>
        ws
        ->Array.filter(w => !(w.tmdbId == tmdbId && w.mediaType == mediaType))
        ->Array.concat([record])
      )
    } catch {
    | _ => ()
    }
  | None => ()
  }
}

let remove = async (~tmdbId, ~mediaType) => {
  switch Signal.get(Auth.session) {
  | Some({did, agent}) =>
    try {
      let _ = await AtProto.deleteRecord(
        agent,
        "com.atproto.repo.deleteRecord",
        {
          repo: did,
          collection,
          rkey: rkey(mediaType, tmdbId),
        },
      )
      Signal.update(items, ws =>
        ws->Array.filter(w => !(w.tmdbId == tmdbId && w.mediaType == mediaType))
      )
    } catch {
    | _ => ()
    }
  | None => ()
  }
}

let loadForUser = async (did, agent) => {
  try {
    let resp = await AtProto.listRecords(
      agent,
      "com.atproto.repo.listRecords",
      {
        repo: did,
        collection,
        limit: 100,
      },
    )
    let records = resp.data.records->Array.filterMap(entry =>
      try {
        Some(entry.value->S.parseOrThrow(wishlistRecordSchema))
      } catch {
      | _ => None
      }
    )
    Signal.set(items, records)
  } catch {
  | _ => ()
  }
}

let isInWishlist = (tmdbId, mediaType) => {
  Signal.get(items)->Array.some(w => w.tmdbId == tmdbId && w.mediaType == mediaType)
}
