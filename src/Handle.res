@schema
type t = string

let toString = handle => handle->String.startsWith("did:") ? handle : `@${handle}`

let fromString = handle => handle->String.startsWith("@") ? handle->String.slice(~start=1) : handle
