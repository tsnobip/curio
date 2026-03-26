@schema
type t = {
  did: Handle.t,
  handle: Handle.t,
  avatar: @s.nullable option<string>,
  displayName: @s.nullable option<string>,
}
