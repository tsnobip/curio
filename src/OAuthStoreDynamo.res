// DynamoDB implementation of OAuth state/session stores.
//
// Table: curio-oauth
// PK: key
// SK: store_type ("state" or "session")

let tableName = switch Bun.env->Bun.Env.get("OAUTH_TABLE") {
| Some(t) => t
| None => "curio-oauth"
}

let client = DynamoDB.make()

let makeStore = (storeType: string): OAuthStoreTypes.store => {
  set: async (key, val) => {
    let serialized = switch JSON.stringifyAny(val) {
    | Some(s) => s
    | None => "null"
    }
    let _ = await client->DynamoDB.send(
      DynamoDB.putCommand({
        "TableName": tableName,
        "Item": {
          "pk": key,
          "sk": storeType,
          "value": serialized,
        },
      }),
    )
  },
  get: async key => {
    let resp = await client->DynamoDB.query(
      DynamoDB.queryCommand({
        "TableName": tableName,
        "KeyConditionExpression": "pk = :pk AND sk = :sk",
        "ExpressionAttributeValues": {
          ":pk": key,
          ":sk": storeType,
        },
        "Limit": 1,
      }),
    )
    switch resp.items->Option.getOr([])->Array.get(0) {
    | Some(item) =>
      let dict = item->JSON.Decode.object->Option.getOr(Dict.make())
      switch dict->Dict.get("value") {
      | Some(JSON.String(s)) => Some(JSON.parseOrThrow(s))
      | _ => None
      }
    | None => None
    }
  },
  del: async key => {
    let _ = await client->DynamoDB.send(
      DynamoDB.deleteCommand({
        "TableName": tableName,
        "Key": {
          "pk": key,
          "sk": storeType,
        },
      }),
    )
  },
}

let stateStore = makeStore("state")
let sessionStore = makeStore("session")

// --- Distributed lock via DynamoDB conditional writes ---
// Uses a row with pk="LOCK", sk="request" and a TTL to prevent deadlocks.
// Acquires by conditional PutItem (attribute_not_exists OR expired).
// Releases by deleting the lock row.

let lockTtlSeconds = 30
let lockRetryMs = 200
let lockMaxRetries = 50

let acquireLock = async () => {
  let nowSeconds = Date.now() /. 1000.0
  let expiresAt = nowSeconds +. Int.toFloat(lockTtlSeconds)
  let rec attempt = async (~retries) => {
    if retries <= 0 {
      panic("Failed to acquire OAuth request lock after max retries")
    }
    try {
      let _ = await client->DynamoDB.send(
        DynamoDB.putCommand({
          "TableName": tableName,
          "Item": {
            "pk": "LOCK",
            "sk": "request",
            "expires_at": expiresAt,
          },
          "ConditionExpression": "attribute_not_exists(pk) OR expires_at < :now",
          "ExpressionAttributeValues": {
            ":now": nowSeconds,
          },
        }),
      )
    } catch {
    | _ =>
      await Promise.make((resolve, _reject) => {
        let _ = setTimeout(() => resolve(), lockRetryMs)
      })
      await attempt(~retries=retries - 1)
    }
  }
  await attempt(~retries=lockMaxRetries)
}

let releaseLock = async () => {
  let _ = await client->DynamoDB.send(
    DynamoDB.deleteCommand({
      "TableName": tableName,
      "Key": {
        "pk": "LOCK",
        "sk": "request",
      },
    }),
  )
}

let requestLock = Some(
  async () => {
    await acquireLock()
  },
)
