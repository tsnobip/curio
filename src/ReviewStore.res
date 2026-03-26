@schema
type review = {
  mediaKey: string,
  did: Handle.t,
  rating: int,
  review: @s.nullable option<string>,
  title: string,
  @as("poster_path") posterPath: string,
  @as("media_type") mediaType: string,
  @as("tmdb_id") tmdbId: int,
  handle: Handle.t,
  avatar: @s.nullable option<string>,
  @as("created_at") createdAt: Spacetime.t,
}

// --- SQLite Setup ---

let db = BunSqlite.Database.make("data/reviews.db")
db
->BunSqlite.Database.query("PRAGMA journal_mode=WAL")
->BunSqlite.Statement.run({"_": 0})
->ignore
db
->BunSqlite.Database.query(`CREATE TABLE IF NOT EXISTS reviews (
      media_key TEXT NOT NULL,
      did TEXT NOT NULL,
      rating INTEGER NOT NULL,
      review TEXT,
      title TEXT NOT NULL,
      poster_path TEXT NOT NULL,
      media_type TEXT NOT NULL,
      tmdb_id INTEGER NOT NULL,
      handle TEXT NOT NULL,
      avatar TEXT,
      created_at TEXT NOT NULL,
      PRIMARY KEY (media_key, did)
    )`)
->BunSqlite.Statement.run({"_": 0})
->ignore
db
->BunSqlite.Database.query(
  "CREATE INDEX IF NOT EXISTS idx_reviews_recent ON reviews (created_at DESC)",
)
->BunSqlite.Statement.run({"_": 0})
->ignore
db
->BunSqlite.Database.query(
  "CREATE INDEX IF NOT EXISTS idx_reviews_user ON reviews (did, created_at DESC)",
)
->BunSqlite.Statement.run({"_": 0})
->ignore

// --- Positional param helpers (same pattern as OAuth.res) ---

module Stmt = {
  @send @variadic
  external run: (BunSqlite.Statement.t, array<string>) => unit = "run"

  @send @variadic
  external all: (BunSqlite.Statement.t, array<string>) => array<JSON.t> = "all"
}

// --- Store Operations ---

let mediaKey = (~mediaType, ~tmdbId) => `${mediaType}#${Int.toString(tmdbId)}`

let put = (r: review) => {
  db
  ->BunSqlite.Database.query(`INSERT OR REPLACE INTO reviews
     (media_key, did, rating, review, title, poster_path, media_type, tmdb_id, handle, avatar, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`)
  ->Stmt.run([
    r.mediaKey,
    Handle.toString(r.did),
    Int.toString(r.rating),
    r.review->Option.getOr(""),
    r.title,
    r.posterPath,
    r.mediaType,
    Int.toString(r.tmdbId),
    Handle.toString(r.handle),
    r.avatar->Option.getOr(""),
    r.createdAt->Spacetime.format(#iso),
  ])
}

let delete = (~mediaKey, ~did: Handle.t) => {
  db
  ->BunSqlite.Database.query("DELETE FROM reviews WHERE media_key = ? AND did = ?")
  ->Stmt.run([mediaKey, Handle.toString(did)])
}

let rowToReview = (json: JSON.t): review => {
  let r = S.convertOrThrow(json, reviewSchema)
  {
    ...r,
    review: if r.review->Option.getOr("") == "" {
      None
    } else {
      r.review
    },
    avatar: if r.avatar->Option.getOr("") == "" {
      None
    } else {
      r.avatar
    },
  }
}

let getForMedia = (~mediaKey, ~excludeDid: option<Handle.t>=?) => {
  let rows = switch excludeDid {
  | Some(did) =>
    db
    ->BunSqlite.Database.query(
      "SELECT * FROM reviews WHERE media_key = ? AND did != ? ORDER BY created_at DESC LIMIT 50",
    )
    ->Stmt.all([mediaKey, Handle.toString(did)])
  | None =>
    db
    ->BunSqlite.Database.query(
      "SELECT * FROM reviews WHERE media_key = ? ORDER BY created_at DESC LIMIT 50",
    )
    ->Stmt.all([mediaKey])
  }
  rows->Array.map(rowToReview)
}

let getRecent = (~limit=20) => {
  db
  ->BunSqlite.Database.query("SELECT * FROM reviews ORDER BY created_at DESC LIMIT ?")
  ->Stmt.all([Int.toString(limit)])
  ->Array.map(rowToReview)
}

let getForUser = (~did: Handle.t, ~limit=20) => {
  db
  ->BunSqlite.Database.query("SELECT * FROM reviews WHERE did = ? ORDER BY created_at DESC LIMIT ?")
  ->Stmt.all([Handle.toString(did), Int.toString(limit)])
  ->Array.map(rowToReview)
}
