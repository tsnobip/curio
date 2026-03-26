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
