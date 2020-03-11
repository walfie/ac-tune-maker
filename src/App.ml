open Tea
open Tea.App
open Tea.Html

module Player = struct
  type onNoteArgs =
    { index : int
    ; note : string
    }

  type onNote = onNoteArgs -> unit
  type onStop = unit -> unit
  type player

  external create : unit -> player = "default" [@@bs.module "./player"] [@@bs.new]
  external stop : player -> unit = "stop" [@@bs.send]

  external play : player -> string -> onNote:onNote -> onStop:onStop -> unit = "play"
    [@@bs.send]

  external play_no_callback : player -> string -> unit = "play" [@@bs.send]
end

let player = Player.create ()

type msg =
  | Play
  | Stop
  | Reset
  | KeyPressed of Keyboard.key
  | PlayingNote of int option
  | UpdateNote of int * Note.note
  | UrlChange of Web.Location.location
[@@bs.deriving { accessors }]

type route = Index

let default_notes =
  let open Note in
  [ G; Hold; A; Hold; B; G; A; B; Hold; G; A; B; Hold; C; Hold; B ]
;;

type state =
  { route : route
  ; notes : Note.note list
  ; playing_note : int option
  ; selected_note : int
  }

let locationToRoute location =
  match location.Web.Location.hash |> String.split_on_char '/' |> List.tl with
  | _ -> Index
;;

let init () location =
  ( { route = locationToRoute location
    ; notes = default_notes
    ; playing_note = None
    ; selected_note = 0
    }
  , Cmd.none )
;;

let update_at_index l index new_value =
  let replace i old_value = if i = index then new_value else old_value in
  List.mapi replace l
;;

let update model = function
  | Play ->
    let notes_string = model.notes |> List.map Note.string_of_note |> String.concat "" in
    let play_notes (cb : msg Vdom.applicationCallbacks ref) =
      let on_stop () = !cb.enqueue (PlayingNote None) in
      let on_note (args : Player.onNoteArgs) =
        PlayingNote (Some args.index) |> !cb.enqueue
      in
      Player.play player notes_string ~onNote:on_note ~onStop:on_stop
    in
    model, Cmd.call play_notes
  | Stop -> model, Cmd.call (fun _ -> Player.stop player)
  | Reset -> { model with notes = List.init 16 (fun _ -> Note.Rest) }, Cmd.msg Stop
  | KeyPressed key ->
    (match key with
    | Keyboard.Up -> model, Cmd.none (* TODO *)
    | Keyboard.Down -> model, Cmd.none (* TODO *)
    | Keyboard.Left ->
      { model with selected_note = max 0 (model.selected_note - 1) }, Cmd.none
    | Keyboard.Right ->
      { model with selected_note = min 15 (model.selected_note + 1) }, Cmd.none)
  | PlayingNote maybe_index -> { model with playing_note = maybe_index }, Cmd.none
  | UrlChange location -> { model with route = locationToRoute location }, Cmd.none
  | UpdateNote (index, new_note) ->
    let new_notes = model.notes |. update_at_index index new_note in
    let play_note _ =
      match new_note with
      | Note.Rest | Note.Hold | Note.Random -> ()
      | _ -> player |. Player.play_no_callback (Note.string_of_note new_note)
    in
    { model with notes = new_notes }, Cmd.call play_note
;;

let view model =
  let open Tea.Html.Attributes in
  let frog_note index note =
    let is_playing = model.playing_note = Some index in
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
      ; FrogSvg.frog_svg note is_playing
      ; button [ disabled previous_disabled; on_previous ] [ text {js|▼|js} ]
      ]
  in
  div
    []
    [ button [ onClick Play ] [ text "Play" ]
    ; button [ onClick Stop ] [ text "Stop" ]
    ; button [ onClick Reset ] [ text "Reset" ]
    ; hr [] []
    ; div [ class' "ac-frogs" ] (model.notes |> List.mapi frog_note)
    ]
;;

let subscriptions _ = Sub.map keyPressed Keyboard.pressed

let main =
  Tea.Navigation.navigationProgram
    urlChange
    { init; update; view; subscriptions; shutdown = (fun _ -> Cmd.none) }
;;
