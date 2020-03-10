open Tea
open Tea.App
open Tea.Html
open Tea.Html.Attributes

module Player = struct
  type player

  external create : unit -> player = "default" [@@bs.module "./player"] [@@bs.new]
  external stop : player -> unit = "stop" [@@bs.send]
  external play : player -> string -> unit = "play" [@@bs.send]
end

let player = Player.create ()

type msg =
  | Play
  | Stop
  | UpdateNote of int * Note.note
  | UrlChange of Web.Location.location
[@@bs.deriving { accessors }]

type route = Index

(* List.init 16 (fun _ -> Note.Rest) *)
let default_notes =
  let open Note in
  [ G; Hold; A; Hold; B; G; A; B; Hold; G; A; B; Hold; C; Hold; B ]
;;

type state =
  { route : route
  ; notes : Note.note list
  }

let locationToRoute location =
  match location.Web.Location.hash |> String.split_on_char '/' |> List.tl with
  | _ -> Index
;;

let init () location =
  { route = locationToRoute location; notes = default_notes }, Cmd.none
;;

let update_at_index l index new_value =
  let replace i old_value = if i = index then new_value else old_value in
  List.mapi replace l
;;

let update model = function
  | Play ->
    let play_notes _ =
      model.notes
      |> List.map Note.string_of_note
      |> String.concat ""
      |> Player.play player
    in
    model, Cmd.call play_notes
  | Stop -> model, Cmd.call (fun _ -> Player.stop player)
  | UrlChange location -> { model with route = locationToRoute location }, Cmd.none
  | UpdateNote (index, new_note) ->
    let play_note _ =
      let note_string = Note.string_of_note new_note in
      player |. Player.play note_string
    in
    let new_notes = model.notes |. update_at_index index new_note in
    { model with notes = new_notes }, Cmd.call play_note
;;

let view model =
  let frog_note index note =
    let next_note = Note.next_note note in
    let previous_note = Note.previous_note note in
    let next_disabled = Belt.Option.isNone next_note in
    let previous_disabled = Belt.Option.isNone previous_note in
    let update_note n = UpdateNote (index, n) |> onClick in
    let on_next = next_note |. Belt.Option.mapWithDefault noProp update_note in
    let on_previous = previous_note |. Belt.Option.mapWithDefault noProp update_note in
    div
      [ class' "ac-frog-container" ]
      [ button [ disabled next_disabled; on_next ] [ text {js|▲|js} ]
      ; FrogSvg.frog_svg note
      ; button [ disabled previous_disabled; on_previous ] [ text {js|▼|js} ]
      ]
  in
  div
    []
    [ button [ onClick Play ] [ text "Play" ]
    ; button [ onClick Stop ] [ text "Stop" ]
    ; hr [] []
    ; div [ class' "ac-frogs" ] (model.notes |> List.mapi frog_note)
    ]
;;

let main =
  Tea.Navigation.navigationProgram
    urlChange
    { init
    ; update
    ; view
    ; subscriptions = (fun _ -> Sub.none)
    ; shutdown = (fun _ -> Cmd.none)
    }
;;
