// Re-export types
type review = ReviewStoreTypes.review
let reviewSchema = ReviewStoreTypes.reviewSchema
let mediaKey = ReviewStoreTypes.mediaKey

let impl = if Env.isProduction {
  module(ReviewStoreDynamo: ReviewStoreTypes.Impl)
} else {
  module(ReviewStoreSqlite: ReviewStoreTypes.Impl)
}

include unpack(impl)
