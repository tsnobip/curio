/** Add $type field to a JSON object for AT Protocol records */
let addType = (json, typ) => {
  switch json {
  | JSON.Object(dict) => Dict.set(dict, "$type", JSON.String(typ))
  | _ => ()
  }
  json
}

/** Event helpers — cast Dom.event to WebAPI record types */
external asInputEvent: Dom.event => WebAPI.EventAPI.event = "%identity"
external asKeyboardEvent: Dom.event => WebAPI.UIEventsAPI.keyboardEvent = "%identity"
external targetAsInput: WebAPI.EventAPI.eventTarget => WebAPI.DOMAPI.htmlInputElement = "%identity"

let inputValue = evt => {
  let e = asInputEvent(evt)
  switch e.target {
  | Value(t) => targetAsInput(t).value
  | Null => ""
  }
}

let keyboardKey = evt => asKeyboardEvent(evt).key
