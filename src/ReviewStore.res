// Re-export types
type review = ReviewStoreTypes.review
let reviewSchema = ReviewStoreTypes.reviewSchema
let mediaKey = ReviewStoreTypes.mediaKey

let isProduction = Bun.env->Bun.Env.get("NODE_ENV") === Some("production")

let impl = if Bun.env.node_env === Some("production") {
  module(ReviewStoreDynamo: ReviewStoreTypes.Impl)
} else {
  module(ReviewStoreSqlite: ReviewStoreTypes.Impl)
}

include unpack(impl)
