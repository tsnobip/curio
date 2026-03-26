// DynamoDB implementation of ReviewStore.
//
// Table: curio-reviews
// PK: mediaKey (e.g. "movie#123")
// SK: did
// GSI1 (RecentIndex): gsi1pk = "RECENT", gsi1sk = createdAt
// GSI2 (UserIndex): gsi2pk = did, gsi2sk = createdAt

let tableName = switch Bun.env->Bun.Env.get("REVIEW_TABLE") {
| Some(t) => t
| None => "curio-reviews"
}

let client = DynamoDB.make()

// --- Helpers ---

let itemToReview = (json: JSON.t): ReviewStoreTypes.review => {
  S.convertOrThrow(json, ReviewStoreTypes.reviewSchema)
}

// --- Store Operations ---

let put = async (r: ReviewStoreTypes.review) => {
  let _ = await client->DynamoDB.send(
    DynamoDB.putCommand({
      "TableName": tableName,
      "Item": {
        "media_key": r.mediaKey,
        "did": Handle.toString(r.did),
        "rating": r.rating,
        "review": r.review->Option.getOr(""),
        "title": r.title,
        "poster_path": r.posterPath,
        "media_type": r.mediaType,
        "tmdb_id": r.tmdbId,
        "handle": Handle.toString(r.handle),
        "avatar": r.avatar->Option.getOr(""),
        "created_at": r.createdAt->Spacetime.format(#iso),
        "gsi1pk": "RECENT",
        "gsi1sk": r.createdAt->Spacetime.format(#iso),
        "gsi2pk": Handle.toString(r.did),
        "gsi2sk": r.createdAt->Spacetime.format(#iso),
      },
    }),
  )
}

let delete = async (~mediaKey, ~did: Handle.t) => {
  let _ = await client->DynamoDB.send(
    DynamoDB.deleteCommand({
      "TableName": tableName,
      "Key": {
        "media_key": mediaKey,
        "did": Handle.toString(did),
      },
    }),
  )
}

let getForMedia = async (~mediaKey, ~excludeDid: option<Handle.t>=?) => {
  let resp = await client->DynamoDB.query(
    DynamoDB.queryCommand({
      "TableName": tableName,
      "KeyConditionExpression": "media_key = :mk",
      "ExpressionAttributeValues": {
        ":mk": mediaKey,
      },
      "ScanIndexForward": false,
      "Limit": 50,
    }),
  )
  let reviews = resp.items->Option.getOr([])->Array.map(itemToReview)
  switch excludeDid {
  | Some(did) => reviews->Array.filter(r => r.did != did)
  | None => reviews
  }
}

let getRecent = async (~limit=20) => {
  let resp = await client->DynamoDB.query(
    DynamoDB.queryCommand({
      "TableName": tableName,
      "IndexName": "RecentIndex",
      "KeyConditionExpression": "gsi1pk = :pk",
      "ExpressionAttributeValues": {
        ":pk": "RECENT",
      },
      "ScanIndexForward": false,
      "Limit": limit,
    }),
  )
  resp.items->Option.getOr([])->Array.map(itemToReview)
}

let getForUser = async (~did: Handle.t, ~limit=20) => {
  let resp = await client->DynamoDB.query(
    DynamoDB.queryCommand({
      "TableName": tableName,
      "IndexName": "UserIndex",
      "KeyConditionExpression": "gsi2pk = :did",
      "ExpressionAttributeValues": {
        ":did": Handle.toString(did),
      },
      "ScanIndexForward": false,
      "Limit": limit,
    }),
  )
  resp.items->Option.getOr([])->Array.map(itemToReview)
}
