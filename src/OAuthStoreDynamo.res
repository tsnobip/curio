// DynamoDB implementation of OAuth state/session stores.
//
// Table: curio-oauth
// PK: key
// SK: store_type ("state" or "session")

let tableName = Env.oauthTable

let client = DynamoDB.make()

/** DocumentClient returns plain objects; `JSON.Decode` may not classify `value` as JSON.String. */
let itemValueString: JSON.t => option<string> = %raw(`
  function (item) {
    if (item == null || typeof item !== "object") return
    var v = item.value
    return typeof v === "string" ? v : undefined
  }
`)

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
    let resp = await client->DynamoDB.getItem(
      DynamoDB.getCommand({
        "TableName": tableName,
        "Key": {
          "pk": key,
          "sk": storeType,
        },
        "ConsistentRead": true,
      }),
    )
    switch resp.item {
    | Some(item) =>
      switch itemValueString(item) {
      | Some(s) => Some(JSON.parseOrThrow(s))
      | None => None
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

let rethrow: exn => 'a = %raw(`function (e) { throw e }`)

let requestLock = Some(
  Obj.magic(
    async (_name, fn) => {
      await acquireLock()
      try {
        let r = await fn()
        await releaseLock()
        r
      } catch {
      | exn =>
        await releaseLock()
        rethrow(exn)
      }
    },
  ),
)
