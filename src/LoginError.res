/** Login error shown after redirect; URL carries `?error=<slug>` only, not user-facing text. */
@unboxed
type t =
  | @as("handle") CouldNotResolveHandle
  | @as("oauth") LoginFailed
  | Other(string)

let message = (x: t): string =>
  switch x {
  | CouldNotResolveHandle => "Could not resolve handle. Check your handle and try again."
  | LoginFailed => "Login failed. Please try again."
  | Other(msg) => msg
  }
