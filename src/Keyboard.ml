open Tea

type key =
  | Up
  | Down
  | Left
  | Right
  | ChangeNote of Note.note

let of_note note = ChangeNote note

let key_of_string = function
  | "ArrowLeft" -> Some Left
  | "ArrowUp" -> Some Up
  | "ArrowRight" -> Some Right
  | "ArrowDown" -> Some Down
  | other when String.length other == 1 -> Note.of_char other |. Belt.Option.map of_note
  | _ -> None
;;

(* TODO: Ignore key when ctrl or cmd are pressed *)
let decode_event =
  let open Tea.Json in
  Decoder.field "key" Decoder.string |> Decoder.map key_of_string
;;

let pressed =
  let open Vdom in
  let subscriptionId = "keyboard" in
  let eventId = "keydown" in
  let enableCall cb =
    let fn event =
      match Json.Decoder.decodeEvent decode_event event with
      | Result.Ok (Some key) ->
        let _ = event##preventDefault () in
        Some key
      | _ -> None
    in
    let handler = EventHandlerCallback (subscriptionId, fn) in
    let doc = Web_node.document_node in
    let cache = eventHandler_Register (ref cb) doc eventId handler in
    fun () ->
      let _ = eventHandler_Unregister doc eventId cache in
      ()
  in
  Tea.Sub.registration subscriptionId enableCall
;;
