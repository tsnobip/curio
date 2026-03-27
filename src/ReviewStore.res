// Re-export types
type review = ReviewStoreTypes.review
let reviewSchema = ReviewStoreTypes.reviewSchema
let mediaKey = ReviewStoreTypes.mediaKey

let impl =
  Bun.env.node_env === Some("production")
    ? module(ReviewStoreDynamo: ReviewStoreTypes.Impl)
    : module(ReviewStoreSqlite: ReviewStoreTypes.Impl)

include unpack(impl)
