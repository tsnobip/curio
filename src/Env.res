let isDev = BunUtils.isDev
let isTesting = Bun.env->Bun.Env.get("TESTING") === Some("true")

let require = (name: string) =>
  switch Bun.env->Bun.Env.get(name) {
  | Some(v) => v
  | None if isTesting => ""
  | None => panic(`${name} environment variable is required`)
  }

let port = switch Bun.env->Bun.Env.get("PORT") {
| Some(p) => Int.fromString(p)->Option.getOr(4444)
| None => 4444
}

let tmdbApiKey = require("TMDB_API_KEY")

let trimTrailingSlash = (url: string) => {
  let n = url->String.length
  if n > 1 && url->String.endsWith("/") {
    url->String.slice(~start=0, ~end=n - 1)
  } else {
    url
  }
}

/** Set on the Lambda by CDK (`https://…`); locally from env or dev default. Never rely on inferring from `Host`. */
let publicUrl = {
  let raw = switch Bun.env->Bun.Env.get("PUBLIC_URL") {
  | Some(url) => url
  | None if isDev || isTesting => "http://127.0.0.1:5173"
  | None => panic("PUBLIC_URL environment variable is required in production")
  }
  let u = trimTrailingSlash(raw)
  // Misconfigured Lambda (e.g. http://localhost:8080) breaks OAuth client-metadata (RFC 8252).
  switch Bun.env->Bun.Env.get("AWS_LAMBDA_FUNCTION_NAME") {
  | Some(_) =>
    if u->String.includes("localhost") || u->String.includes("127.0.0.1") {
      panic(
        "PUBLIC_URL must be the site origin (e.g. https://curio.social), not loopback. Update the Lambda environment.",
      )
    }
  | None => ()
  }
  u
}

let reviewTable = switch Bun.env->Bun.Env.get("REVIEW_TABLE") {
| Some(t) => t
| None => "curio-reviews"
}

let oauthTable = switch Bun.env->Bun.Env.get("OAUTH_TABLE") {
| Some(t) => t
| None => "curio-oauth"
}

let dynamoEndpoint = Bun.env->Bun.Env.get("DYNAMODB_ENDPOINT")
