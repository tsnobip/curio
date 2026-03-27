@module("node:fs")
external mkdirSync: (string, {"recursive": bool}) => unit = "mkdirSync"

let dbLazy = Lazy.make(() => {
  mkdirSync("data", {"recursive": true})
  let db = BunSqlite.Database.make("data/oauth.db")
  db
  ->BunSqlite.Database.query(
    "CREATE TABLE IF NOT EXISTS oauth_state (key TEXT PRIMARY KEY, value TEXT NOT NULL)",
  )
  ->BunSqlite.Statement.run({"_": 0})
  ->ignore
  db
  ->BunSqlite.Database.query(
    "CREATE TABLE IF NOT EXISTS oauth_session (key TEXT PRIMARY KEY, value TEXT NOT NULL)",
  )
  ->BunSqlite.Statement.run({"_": 0})
  ->ignore
  db
})

let getDb = () => dbLazy->Lazy.get

let safeStringify = (val: 'a): string => {
  switch JSON.stringifyAny(val) {
  | Some(s) => s
  | None => "null"
  }
}

module Stmt = {
  type sqliteRow = {value: string}

  type param = string
  @send @variadic
  external run: (BunSqlite.Statement.t, array<param>) => unit = "run"

  @send
  external get: (BunSqlite.Statement.t, array<param>) => Nullable.t<sqliteRow> = "get"
}

let makeStore = (table: string): OAuthStoreTypes.store => {
  set: async (key, val) => {
    let db = getDb()
    let serialized = safeStringify(val)
    db
    ->BunSqlite.Database.query(`INSERT OR REPLACE INTO ${table} (key, value) VALUES (?, ?)`)
    ->Stmt.run([key, serialized])
  },
  get: async key => {
    let db = getDb()
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
    let db = getDb()
    db
    ->BunSqlite.Database.query(`DELETE FROM ${table} WHERE key = ?`)
    ->Stmt.run([key])
  },
}

let stateStore = makeStore("oauth_state")
let sessionStore = makeStore("oauth_session")
let requestLock: option<(string, unit => promise<unit>) => promise<unit>> = None
