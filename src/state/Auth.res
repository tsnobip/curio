open Xote

type authState = {
  did: string,
  handle: string,
  agent: AtProto.agent,
}

let session: Signal.t<option<authState>> = Signal.make(None)
let isLoggedIn = Computed.make(() => Signal.get(session)->Option.isSome)
let isLoading = Signal.make(true)

let client: ref<option<AtProto.oauthClient>> = ref(None)
let oauthSession: ref<option<AtProto.oauthSession>> = ref(None)

let handleSessionReady = rawSession => {
  oauthSession := Some(rawSession)
  let info = AtProto.sessionInfo(rawSession)
  let agent = AtProto.makeAgent(rawSession)
  Signal.set(session, Some({did: info.did, handle: info.handle, agent}))
}

let initialize = async () => {
  let c = AtProto.makeOAuthClient({
    "clientId": "http://localhost",
    "handleResolver": "https://bsky.social",
  })
  client := Some(c)

  try {
    let result = await AtProto.init(c)
    switch result {
    | Some(rawSession) => handleSessionReady(rawSession)
    | None => ()
    }
  } catch {
  | _ => ()
  }

  Signal.set(isLoading, false)
}

let login = async handle => {
  switch client.contents {
  | Some(c) =>
    try {
      await AtProto.signIn(c, handle, {"signal": Nullable.undefined})
    } catch {
    | _ => ()
    }
  | None => ()
  }
}

let logout = async () => {
  switch oauthSession.contents {
  | Some(s) =>
    try {
      await AtProto.revoke(s)
    } catch {
    | _ => ()
    }
  | None => ()
  }
  oauthSession := None
  Signal.set(session, None)
}
