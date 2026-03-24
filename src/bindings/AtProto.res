type oauthClient
type oauthSession

type sessionInfo = {
  did: string,
  handle: string,
}

@module("@atproto/oauth-client-browser") @new
external makeOAuthClient: {..} => oauthClient = "BrowserOAuthClient"

@send external init: oauthClient => promise<option<oauthSession>> = "init"

@send external signIn: (oauthClient, string, {..}) => promise<unit> = "signIn"

@send external revoke: oauthSession => promise<unit> = "revoke"

/** Extract did/handle from raw session object */
external sessionInfo: oauthSession => sessionInfo = "%identity"

type agent

@module("@atproto/api") @new
external makeAgent: oauthSession => agent = "Agent"

type putRecordInput<'a> = {
  repo: string,
  collection: string,
  rkey: string,
  record: 'a,
}

type deleteRecordInput = {
  repo: string,
  collection: string,
  rkey: string,
}

type listRecordsInput = {
  repo: string,
  collection: string,
  limit: int,
}

type recordEntry = {
  uri: string,
  value: JSON.t,
}

type listRecordsOutput = {records: array<recordEntry>}

type apiResponse<'a> = {data: 'a}

@send
external putRecord: (
  agent,
  string,
  putRecordInput<'a>,
) => promise<apiResponse<{..}>> = "call"

@send
external deleteRecord: (
  agent,
  string,
  deleteRecordInput,
) => promise<apiResponse<{..}>> = "call"

@send
external listRecords: (
  agent,
  string,
  listRecordsInput,
) => promise<apiResponse<listRecordsOutput>> = "call"
