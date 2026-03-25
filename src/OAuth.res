// --- Bindings ---

type oauthClient
type oauthSession

type clientMetadata = {
  client_id: string,
  redirect_uris: array<string>,
  scope: string,
  grant_types: array<string>,
  response_types: array<string>,
  application_type: string,
  token_endpoint_auth_method: string,
  dpop_bound_access_tokens: bool,
}

type store = {
  set: (string, JSON.t) => promise<unit>,
  get: string => promise<option<JSON.t>>,
  del: string => promise<unit>,
}

type clientOptions = {
  clientMetadata: clientMetadata,
  stateStore: store,
  sessionStore: store,
}

@module("@atproto/oauth-client-node") @new
external makeClient: clientOptions => oauthClient = "NodeOAuthClient"

type authorizeOptions = {scope: string}

@send
external authorize: (oauthClient, string, authorizeOptions) => promise<URL.t> = "authorize"

type callbackResult = {session: oauthSession}

@send
external callback: (oauthClient, URLSearchParams.t) => promise<callbackResult> = "callback"

@send
external restore: (oauthClient, string) => promise<oauthSession> = "restore"

@get external sessionDid: oauthSession => string = "did"

type sessionInfo = {handle: option<string>}
@get external sessionInfoOpt: oauthSession => option<sessionInfo> = "info"

@send external sessionSignOut: oauthSession => promise<unit> = "signOut"

@module("@atproto/api") @new
external agentFromSession: oauthSession => AtProto.agent = "Agent"

// --- SQLite Store ---

let db = BunSqlite.Database.make("data/oauth.db")

let _ =
  db
  ->BunSqlite.Database.query(
    "CREATE TABLE IF NOT EXISTS oauth_state (key TEXT PRIMARY KEY, value TEXT NOT NULL)",
  )
  ->BunSqlite.Statement.run({"_": 0})

let _ =
  db
  ->BunSqlite.Database.query(
    "CREATE TABLE IF NOT EXISTS oauth_session (key TEXT PRIMARY KEY, value TEXT NOT NULL)",
  )
  ->BunSqlite.Statement.run({"_": 0})

let safeStringify = (val: 'a): string => {
  switch JSON.stringifyAny(val) {
  | Some(s) => s
  | None => "null"
  }
}

// Bun SQLite named params are broken in 1.3 — use positional params
module Stmt = {
  type sqliteRow = {value: string}

  type param = string
  @send @variadic
  external run: (BunSqlite.Statement.t, array<param>) => unit = "run"

  @send
  external get: (BunSqlite.Statement.t, array<param>) => Nullable.t<sqliteRow> = "get"
}

let makeSqliteStore = (table: string): store => {
  set: async (key, val) => {
    let serialized = safeStringify(val)
    db
    ->BunSqlite.Database.query(`INSERT OR REPLACE INTO ${table} (key, value) VALUES (?, ?)`)
    ->Stmt.run([key, serialized])
  },
  get: async key => {
    let result =
      db
      ->BunSqlite.Database.query(`SELECT value FROM ${table} WHERE key = ?`)
      ->Stmt.get([key])
    switch result {
    | Value(row) => Some(JSON.parseOrThrow(row.value))
    | Undefined | Null => None
    }
  },
  del: async key => {
    db
    ->BunSqlite.Database.query(`DELETE FROM ${table} WHERE key = ?`)
    ->Stmt.run([key])
  },
}

// --- State ---

let client: ref<option<oauthClient>> = ref(None)

// --- Public API ---

type profileDataFull = {
  avatar: option<string>,
  displayName: option<string>,
  handle: string,
}
type profileResponseFull = {data: profileDataFull}
type getProfileInput = {actor: string}

@send
external getProfileFull: (AtProto.agent, getProfileInput) => promise<profileResponseFull> =
  "getProfile"

let initOAuthClient = (publicUrl: string) => {
  let redirectUri = publicUrl ++ "/oauth/callback"
  let scope = "atproto transition:generic"
  let clientId =
    "http://localhost?redirect_uri=" ++
    encodeURIComponent(redirectUri) ++
    "&scope=" ++
    encodeURIComponent(scope)

  let c = makeClient({
    clientMetadata: {
      client_id: clientId,
      redirect_uris: [redirectUri],
      scope,
      grant_types: ["authorization_code", "refresh_token"],
      response_types: ["code"],
      application_type: "native",
      token_endpoint_auth_method: "none",
      dpop_bound_access_tokens: true,
    },
    stateStore: makeSqliteStore("oauth_state"),
    sessionStore: makeSqliteStore("oauth_session"),
  })
  client := Some(c)
}

let getClient = () =>
  switch client.contents {
  | Some(c) => c
  | None => panic("OAuth client not initialized")
  }

let authorizeUrl = async (handle: string) => {
  let url = await getClient()->authorize(handle, {scope: "atproto transition:generic"})
  url->URL.toString
}

let handleCallback = async (params: URLSearchParams.t): Session.t => {
  let {session} = await getClient()->callback(params)
  let did = sessionDid(session)

  // Fetch profile for handle, avatar, displayName
  let agent = agentFromSession(session)
  let (handle, avatar, displayName) = try {
    let profile = await getProfileFull(agent, {actor: did})
    (profile.data.handle, profile.data.avatar, profile.data.displayName)
  } catch {
  | JsExn(e) =>
    Console.error3("Error fetching profile for", did, e)
    let fallback = switch sessionInfoOpt(session) {
    | Some({handle: Some(h)}) => h
    | _ => did
    }
    (fallback, None, None)
  }

  {did, handle, avatar, displayName}
}

let restoreAgent = async (did: string) => {
  let session = await getClient()->restore(did)
  agentFromSession(session)
}

let signOut = async (did: string) => {
  try {
    let session = await getClient()->restore(did)
    await sessionSignOut(session)
  } catch {
  | JsExn(e) => Console.error2("Error signing out", e)
  }
}
