let isProduction = Bun.env.node_env === Some("production")
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

let publicUrl = switch Bun.env->Bun.Env.get("PUBLIC_URL") {
| Some(url) => url
| None if isDev || isTesting => "http://127.0.0.1:5173"
| None => panic("PUBLIC_URL environment variable is required in production")
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
