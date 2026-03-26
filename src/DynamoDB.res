// Minimal bindings to @aws-sdk/lib-dynamodb (DynamoDBDocumentClient)
// which auto-marshals native JS values, inspired by rescript-aws-sdk-v3-wrapper patterns.

// --- Low-level DynamoDB client ---

type dynamoDBClient
@module("@aws-sdk/client-dynamodb") @new
external createClient: unit => dynamoDBClient = "DynamoDBClient"

// --- Document client (auto-marshals JS objects) ---

type documentClient

type translateConfig = {marshallOptions: {removeUndefinedValues: bool}}

@module("@aws-sdk/lib-dynamodb") @new
external createDocumentClient: (dynamoDBClient, translateConfig) => documentClient =
  "DynamoDBDocumentClient"

let make = () =>
  createDocumentClient(createClient(), {marshallOptions: {removeUndefinedValues: true}})

// --- Commands ---

type command

@module("@aws-sdk/lib-dynamodb") @new
external putCommand: {..} => command = "PutCommand"

@module("@aws-sdk/lib-dynamodb") @new
external deleteCommand: {..} => command = "DeleteCommand"

@module("@aws-sdk/lib-dynamodb") @new
external queryCommand: {..} => command = "QueryCommand"

type queryResponse = {
  @as("Items") items: option<array<JSON.t>>,
  @as("Count") count: option<int>,
}

@send
external send: (documentClient, command) => promise<{..}> = "send"

@send
external query: (documentClient, command) => promise<queryResponse> = "send"
