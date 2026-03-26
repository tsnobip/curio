// Minimal bindings to @aws-sdk/lib-dynamodb (DynamoDBDocumentClient)
// which auto-marshals native JS values, inspired by rescript-aws-sdk-v3-wrapper patterns.

// --- Low-level DynamoDB client ---

type dynamoDBClient

type clientConfig = {
  region?: string,
  endpoint?: string,
  credentials?: {accessKeyId: string, secretAccessKey: string},
}

@module("@aws-sdk/client-dynamodb") @new
external createClient: clientConfig => dynamoDBClient = "DynamoDBClient"

// --- Document client (auto-marshals JS objects) ---

type documentClient

type translateConfig = {marshallOptions: {removeUndefinedValues: bool}}

@module("@aws-sdk/lib-dynamodb") @new
external createDocumentClient: (dynamoDBClient, translateConfig) => documentClient =
  "DynamoDBDocumentClient"

let make = (~config: clientConfig={}) => {
  let config = switch Bun.env->Bun.Env.get("DYNAMODB_ENDPOINT") {
  | Some(endpoint) => {
      endpoint,
      region: config.region->Option.getOr("us-east-1"),
      credentials: config.credentials->Option.getOr({
        accessKeyId: "local",
        secretAccessKey: "local",
      }),
    }
  | None => config
  }
  createDocumentClient(createClient(config), {marshallOptions: {removeUndefinedValues: true}})
}

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

// --- Low-level commands (for table management) ---

type rawCommand

@module("@aws-sdk/client-dynamodb") @new
external createTableCommand: {..} => rawCommand = "CreateTableCommand"

@module("@aws-sdk/client-dynamodb") @new
external deleteTableCommand: {..} => rawCommand = "DeleteTableCommand"

@send
external rawSend: (dynamoDBClient, rawCommand) => promise<{..}> = "send"
