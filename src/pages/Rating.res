type t =
  | Individual(int)
  | Average(float)

@jsx.component
let make = (~rating: t) => {
  let rating = switch rating {
  | Individual(i) => Int.toString(i)
  | Average(f) => Float.toFixed(f, ~digits=1)
  }
  <span className="text-xs text-gold-400"> {Hjsx.string(`★ ${rating}/10`)} </span>
}
