@schema
type t = string

let toString = handle =>
  handle->String.startsWith("did:") || handle->String.startsWith("@") ? handle : `@${handle}`

let fromString = handle => handle->String.startsWith("@") ? handle->String.slice(~start=1) : handle
