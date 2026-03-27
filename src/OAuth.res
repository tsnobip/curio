// --- Bindings ---

type oauthClient
type oauthSession

type clientMetadata = {
  @as("client_id") clientId: string,
  @as("redirect_uris") redirectUris: array<string>,
  scope: string,
  @as("grant_types") grantTypes: array<string>,
  @as("response_types") responseTypes: array<string>,
  @as("application_type") applicationType: string,
  @as("token_endpoint_auth_method") tokenEndpointAuthMethod: string,
  @as("dpop_bound_access_tokens") dpopBoundAccessTokens: bool,
}

type store = OAuthStoreTypes.store

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
external restore: (oauthClient, Handle.t) => promise<oauthSession> = "restore"

@get external sessionDid: oauthSession => Handle.t = "did"

type sessionInfo = {handle: option<Handle.t>}
@get external sessionInfoOpt: oauthSession => option<sessionInfo> = "info"

@send external sessionSignOut: oauthSession => promise<unit> = "signOut"

@module("@atproto/api") @new
external agentFromSession: oauthSession => AtProto.agent = "Agent"

// --- Store (SQLite in dev, DynamoDB in production) ---

let storeImpl =
  Bun.env.node_env === Some("production")
    ? module(OAuthStoreDynamo: OAuthStoreTypes.Impl)
    : module(OAuthStoreSqlite: OAuthStoreTypes.Impl)

module StoreImpl = unpack(storeImpl)

// --- State ---

let client: ref<option<oauthClient>> = ref(None)

// --- Public API ---

type profileDataFull = {
  avatar: option<string>,
  displayName: option<string>,
  handle: Handle.t,
}
type profileResponseFull = {data: profileDataFull}
type getProfileInput = {actor: Handle.t}

@send
external getProfileFull: (AtProto.agent, getProfileInput) => promise<profileResponseFull> =
  "getProfile"

let initOAuthClient = (publicUrl: string) => {
  let redirectUri = `${publicUrl}/oauth/callback`
  let scope = "atproto transition:generic"
  let isLocalhost =
    publicUrl->String.includes("localhost") || publicUrl->String.includes("127.0.0.1")
  let clientId = if isLocalhost {
    "http://localhost?redirect_uri=" ++
    encodeURIComponent(redirectUri) ++
    "&scope=" ++
    encodeURIComponent(scope)
  } else {
    `${publicUrl}/client-metadata.json`
  }

  let clientMetadata = {
    clientId,
    redirectUris: [redirectUri],
    scope,
    grantTypes: ["authorization_code", "refresh_token"],
    responseTypes: ["code"],
    applicationType: if isLocalhost {
      "native"
    } else {
      "web"
    },
    tokenEndpointAuthMethod: "none",
    dpopBoundAccessTokens: true,
  }
  let c = switch StoreImpl.requestLock {
  | None =>
    makeClient({
      clientMetadata,
      stateStore: StoreImpl.stateStore,
      sessionStore: StoreImpl.sessionStore,
    })
  | Some(lockFn) =>
    makeClient(
      Obj.magic(dict{
        "clientMetadata": Obj.magic(clientMetadata),
        "stateStore": Obj.magic(StoreImpl.stateStore),
        "sessionStore": Obj.magic(StoreImpl.sessionStore),
        "requestLock": Obj.magic(lockFn),
      }),
    )
  }
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

let restoreAgent = async (did: Handle.t) => {
  let session = await getClient()->restore(did)
  agentFromSession(session)
}

let signOut = async did => {
  try {
    let session = await getClient()->restore(did)
    await sessionSignOut(session)
  } catch {
  | JsExn(e) => Console.error2("Error signing out", e)
  }
}
