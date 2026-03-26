open Test

let dynamoPort = 8123
let endpoint = `http://localhost:${Int.toString(dynamoPort)}`
let reviewTable = "curio-reviews-test"
let oauthTable = "curio-oauth-test"

// --- DynamoDB table creation bindings ---

@module("@aws-sdk/client-dynamodb") @new
external makeDynamoDBClient: {..} => DynamoDB.dynamoDBClient = "DynamoDBClient"

@module("@aws-sdk/client-dynamodb") @new
external createTableCommand: {..} => DynamoDB.rawCommand = "CreateTableCommand"

@module("@aws-sdk/client-dynamodb") @new
external deleteTableCommand: {..} => DynamoDB.rawCommand = "DeleteTableCommand"

@module("@aws-sdk/client-dynamodb") @new
external listTablesCommand: {..} => DynamoDB.rawCommand = "ListTablesCommand"

type listTablesResponse = {@as("TableNames") tableNames: option<array<string>>}

@send
external rawSendListTables: (DynamoDB.dynamoDBClient, DynamoDB.rawCommand) => promise<listTablesResponse> = "send"

// --- Docker helpers ---

let execSilent = cmd =>
  try {
    ChildProcess.execSyncWith(cmd, {stdio: "pipe"})->ignore
    true
  } catch {
  | _ => false
  }

let waitForDynamo = async rawClient => {
  let rec loop = async (~retries=30) => {
    if retries <= 0 {
      panic("DynamoDB local did not start in time")
    }
    try {
      let _ = await rawSendListTables(rawClient, listTablesCommand({"_": 0}))
    } catch {
    | _ =>
      await Promise.make((resolve, _reject) => {
        let _ = setTimeout(() => resolve(), 500)
      })
      await loop(~retries=retries - 1)
    }
  }
  await loop()
}

// --- Review helpers ---

let makeReview = (
  ~mediaKey,
  ~did,
  ~rating,
  ~review=?,
  ~title,
  ~posterPath,
  ~mediaType,
  ~tmdbId,
  ~handle,
  ~avatar=?,
  ~createdAt,
): ReviewStoreTypes.review => {
  mediaKey,
  did: Handle.fromString(did),
  rating,
  review,
  title,
  posterPath,
  mediaType,
  tmdbId,
  handle: Handle.fromString(handle),
  avatar,
  createdAt: Spacetime.fromStringUnsafe(createdAt),
}

// --- Setup / Teardown ---

let rawClient = ref(None)

beforeAllAsync(async () => {
  // Start DynamoDB Local via Docker
  if !execSilent(`docker run -d --name curio-dynamo-test -p ${Int.toString(dynamoPort)}:8000 amazon/dynamodb-local`) {
    execSilent("docker start curio-dynamo-test")->ignore
  }

  let client = makeDynamoDBClient({
    "region": "us-east-1",
    "endpoint": endpoint,
    "credentials": {"accessKeyId": "local", "secretAccessKey": "local"},
  })
  rawClient := Some(client)

  await waitForDynamo(client)

  // Clean up existing tables
  let resp = await rawSendListTables(client, listTablesCommand({"_": 0}))
  let tables = resp.tableNames->Option.getOr([])
  for i in 0 to Array.length(tables) - 1 {
    let name = tables->Array.getUnsafe(i)
    if name == reviewTable || name == oauthTable {
      let _ = await DynamoDB.rawSend(client, deleteTableCommand({"TableName": name}))
    }
  }

  // Create review table
  let _ = await DynamoDB.rawSend(
    client,
    createTableCommand({
      "TableName": reviewTable,
      "KeySchema": [
        {"AttributeName": "media_key", "KeyType": "HASH"},
        {"AttributeName": "did", "KeyType": "RANGE"},
      ],
      "AttributeDefinitions": [
        {"AttributeName": "media_key", "AttributeType": "S"},
        {"AttributeName": "did", "AttributeType": "S"},
        {"AttributeName": "gsi1pk", "AttributeType": "S"},
        {"AttributeName": "gsi1sk", "AttributeType": "S"},
        {"AttributeName": "gsi2pk", "AttributeType": "S"},
        {"AttributeName": "gsi2sk", "AttributeType": "S"},
      ],
      "GlobalSecondaryIndexes": [
        {
          "IndexName": "RecentIndex",
          "KeySchema": [
            {"AttributeName": "gsi1pk", "KeyType": "HASH"},
            {"AttributeName": "gsi1sk", "KeyType": "RANGE"},
          ],
          "Projection": {"ProjectionType": "ALL"},
        },
        {
          "IndexName": "UserIndex",
          "KeySchema": [
            {"AttributeName": "gsi2pk", "KeyType": "HASH"},
            {"AttributeName": "gsi2sk", "KeyType": "RANGE"},
          ],
          "Projection": {"ProjectionType": "ALL"},
        },
      ],
      "BillingMode": "PAY_PER_REQUEST",
    }),
  )

  // Create oauth table
  let _ = await DynamoDB.rawSend(
    client,
    createTableCommand({
      "TableName": oauthTable,
      "KeySchema": [
        {"AttributeName": "pk", "KeyType": "HASH"},
        {"AttributeName": "sk", "KeyType": "RANGE"},
      ],
      "AttributeDefinitions": [
        {"AttributeName": "pk", "AttributeType": "S"},
        {"AttributeName": "sk", "AttributeType": "S"},
      ],
      "BillingMode": "PAY_PER_REQUEST",
    }),
  )
})

afterAll(() => {
  execSilent("docker rm -f curio-dynamo-test")->ignore
})

// --- ReviewStoreDynamo tests ---

describe("ReviewStoreDynamo", () => {
  testAsync("put and getForMedia", async () => {
    await ReviewStoreDynamo.put(
      makeReview(
        ~mediaKey="movie#100",
        ~did="did:plc:test1",
        ~rating=5,
        ~review="Great movie!",
        ~title="Test Movie",
        ~posterPath="/poster.jpg",
        ~mediaType="movie",
        ~tmdbId=100,
        ~handle="@alice",
        ~createdAt="2025-01-01",
      ),
    )

    let results = await ReviewStoreDynamo.getForMedia(~mediaKey="movie#100")
    expect(Array.length(results))->Expect.toBe(1)
    expect((results->Array.getUnsafe(0)).title)->Expect.toBe("Test Movie")
    expect((results->Array.getUnsafe(0)).rating)->Expect.toBe(5)
  })

  testAsync("put multiple and getRecent returns ordered results", async () => {
    await ReviewStoreDynamo.put(
      makeReview(
        ~mediaKey="movie#200",
        ~did="did:plc:test2",
        ~rating=4,
        ~review="Pretty good",
        ~title="Another Movie",
        ~posterPath="/poster2.jpg",
        ~mediaType="movie",
        ~tmdbId=200,
        ~handle="@bob",
        ~avatar="https://example.com/avatar.jpg",
        ~createdAt="2025-01-02",
      ),
    )

    let recent = await ReviewStoreDynamo.getRecent(~limit=10)
    expect(Array.length(recent))->Expect.toBeGreaterThanOrEqual(2.0)
    expect((recent->Array.getUnsafe(0)).title)->Expect.toBe("Another Movie")
    expect((recent->Array.getUnsafe(1)).title)->Expect.toBe("Test Movie")
  })

  testAsync("getForMedia with excludeDid filters correctly", async () => {
    await ReviewStoreDynamo.put(
      makeReview(
        ~mediaKey="movie#100",
        ~did="did:plc:test3",
        ~rating=3,
        ~review="It was ok",
        ~title="Test Movie",
        ~posterPath="/poster.jpg",
        ~mediaType="movie",
        ~tmdbId=100,
        ~handle="@charlie",
        ~createdAt="2025-01-03",
      ),
    )

    let all = await ReviewStoreDynamo.getForMedia(~mediaKey="movie#100")
    expect(Array.length(all))->Expect.toBe(2)

    let filtered = await ReviewStoreDynamo.getForMedia(
      ~mediaKey="movie#100",
      ~excludeDid=Handle.fromString("did:plc:test1"),
    )
    expect(Array.length(filtered))->Expect.toBe(1)
    expect((filtered->Array.getUnsafe(0)).did->Handle.toString)->Expect.toBe("did:plc:test3")
  })

  testAsync("getForUser returns only that user's reviews", async () => {
    let results = await ReviewStoreDynamo.getForUser(~did=Handle.fromString("did:plc:test1"), ~limit=10)
    expect(Array.length(results))->Expect.toBe(1)
    expect((results->Array.getUnsafe(0)).title)->Expect.toBe("Test Movie")
  })

  testAsync("delete removes the review", async () => {
    await ReviewStoreDynamo.delete(~mediaKey="movie#100", ~did=Handle.fromString("did:plc:test1"))

    let results = await ReviewStoreDynamo.getForMedia(~mediaKey="movie#100")
    expect(Array.length(results))->Expect.toBe(1)
    expect((results->Array.getUnsafe(0)).did->Handle.toString)->Expect.toBe("did:plc:test3")
  })

  testAsync("put with no review stores and retrieves correctly", async () => {
    await ReviewStoreDynamo.put(
      makeReview(
        ~mediaKey="movie#300",
        ~did="did:plc:test4",
        ~rating=3,
        ~title="No Review Movie",
        ~posterPath="/poster3.jpg",
        ~mediaType="movie",
        ~tmdbId=300,
        ~handle="@dave",
        ~createdAt="2025-01-04",
      ),
    )

    let results = await ReviewStoreDynamo.getForMedia(~mediaKey="movie#300")
    expect(Array.length(results))->Expect.toBe(1)
    expect((results->Array.getUnsafe(0)).rating)->Expect.toBe(3)
  })
})

// --- OAuthStoreDynamo tests ---

describe("OAuthStoreDynamo", () => {
  testAsync("stateStore: set and get", async () => {
    let data = JSON.parseOrThrow(`{"foo":"bar","num":42}`)
    await OAuthStoreDynamo.stateStore.set("state-key-1", data)

    let result = await OAuthStoreDynamo.stateStore.get("state-key-1")
    expect(result)->Expect.toEqual(Some(data))
  })

  testAsync("stateStore: get returns None for missing key", async () => {
    let result = await OAuthStoreDynamo.stateStore.get("nonexistent")
    expect(result)->Expect.toBe(None)
  })

  testAsync("stateStore: del removes the entry", async () => {
    let data = JSON.parseOrThrow(`{"a":1}`)
    await OAuthStoreDynamo.stateStore.set("state-key-2", data)
    await OAuthStoreDynamo.stateStore.del("state-key-2")

    let result = await OAuthStoreDynamo.stateStore.get("state-key-2")
    expect(result)->Expect.toBe(None)
  })

  testAsync("sessionStore is independent from stateStore", async () => {
    let sessionData = JSON.parseOrThrow(`{"token":"abc123"}`)
    let stateData = JSON.parseOrThrow(`{"different":true}`)

    await OAuthStoreDynamo.sessionStore.set("shared-key", sessionData)
    await OAuthStoreDynamo.stateStore.set("shared-key", stateData)

    let session = await OAuthStoreDynamo.sessionStore.get("shared-key")
    expect(session)->Expect.toEqual(Some(sessionData))

    let state = await OAuthStoreDynamo.stateStore.get("shared-key")
    expect(state)->Expect.toEqual(Some(stateData))
  })

  testAsync("stateStore: overwrite existing key", async () => {
    let v1 = JSON.parseOrThrow(`{"v":1}`)
    let v2 = JSON.parseOrThrow(`{"v":2}`)

    await OAuthStoreDynamo.stateStore.set("overwrite-key", v1)
    await OAuthStoreDynamo.stateStore.set("overwrite-key", v2)

    let result = await OAuthStoreDynamo.stateStore.get("overwrite-key")
    expect(result)->Expect.toEqual(Some(v2))
  })
})
