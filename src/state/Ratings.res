open Xote

@schema
type ratingRecord = {
  tmdbId: int,
  mediaType: string,
  rating: int,
  title: string,
  posterPath: string,
  createdAt: string,
}

let ratings: Signal.t<array<ratingRecord>> = Signal.make([])

let collection = "social.curio.rating"

let rkey = (mediaType, tmdbId) =>
  mediaType ++ "-" ++ Int.toString(tmdbId)

let rate = async (~tmdbId, ~mediaType, ~rating, ~title, ~posterPath) => {
  switch Signal.get(Auth.session) {
  | Some({did, agent}) =>
    let record = {
      tmdbId,
      mediaType,
      rating,
      title,
      posterPath: posterPath->Option.getOr(""),
      createdAt: Date.make()->Date.toISOString,
    }
    try {
      let _ = await AtProto.putRecord(
        agent,
        "com.atproto.repo.putRecord",
        {
          repo: did,
          collection,
          rkey: rkey(mediaType, tmdbId),
          record: record->S.reverseConvertToJsonOrThrow(ratingRecordSchema)->Util.addType(collection),
        },
      )
      Signal.update(ratings, rs =>
        rs
        ->Array.filter(r => !(r.tmdbId == tmdbId && r.mediaType == mediaType))
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
      Signal.update(ratings, rs =>
        rs->Array.filter(r => !(r.tmdbId == tmdbId && r.mediaType == mediaType))
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
        Some(entry.value->S.parseOrThrow(ratingRecordSchema))
      } catch {
      | _ => None
      }
    )
    Signal.set(ratings, records)
  } catch {
  | _ => ()
  }
}

let getRating = (tmdbId, mediaType) => {
  Signal.get(ratings)->Array.find(r => r.tmdbId == tmdbId && r.mediaType == mediaType)
}
