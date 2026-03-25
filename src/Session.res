@schema
type t = {
  did: string,
  handle: string,
  avatar: @s.nullable option<string>,
  displayName: @s.nullable option<string>,
}
