open Tea
open Tea.App
open Tea.Html

module Player = struct
  type onNoteArgs =
    { index : Tune.Index.t
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
  | SelectNote of Tune.Index.t
  | KeyPressed of Keyboard.key
  | PlayingNote of Tune.Index.t option
  | UpdateNote of Tune.Index.t * Note.note
  | UpdateTune of Tune.t
  | UrlChange of Web.Location.location
[@@bs.deriving { accessors }]

type route =
  | Index
  | Tune of Tune.t

type state =
  { route : route
  ; location : Web.Location.location
  ; tune : Tune.t
  ; playing_index : Tune.Index.t option
  ; selected_index : Tune.Index.t
  }

let locationToRoute location =
  match location.Web.Location.hash |> String.split_on_char '/' |> List.tl with
  | [ "tune"; tune ] -> Tune (Tune.from_string tune)
  | _ -> Index
;;

let init () location =
  let route = locationToRoute location in
  ( { route
    ; tune = Tune.default
    ; playing_index = None
    ; selected_index = Tune.Index.min
    ; location
    }
  , Cmd.msg (UrlChange location) )
;;

let update_at_index l index new_value =
  let replace i old_value = if i = index then new_value else old_value in
  List.mapi replace l
;;

let update model = function
  | Play ->
    let tune_string = Tune.to_string model.tune in
    let play_tune (cb : msg Vdom.applicationCallbacks ref) =
      let on_stop () = !cb.enqueue (PlayingNote None) in
      let on_note (args : Player.onNoteArgs) =
        PlayingNote (Some args.index) |> !cb.enqueue
      in
      Player.play player tune_string ~onNote:on_note ~onStop:on_stop
    in
    model, Cmd.call play_tune
  | Stop -> model, Cmd.call (fun _ -> Player.stop player)
  | Reset -> { model with tune = Tune.empty }, Cmd.msg Stop
  | SelectNote index -> { model with selected_index = index }, Cmd.none
  | UpdateTune tune -> { model with tune }, Cmd.none
  | KeyPressed key ->
    let update_note_cmd model f =
      model.tune
      |> Tune.get model.selected_index
      |> f
      |. Belt.Option.mapWithDefault Cmd.none (fun n ->
             Cmd.msg (updateNote model.selected_index n))
    in
    (match key with
    | Keyboard.Up -> model, update_note_cmd model Note.next
    | Keyboard.Down -> model, update_note_cmd model Note.prev
    | Keyboard.Left ->
      ( { model with selected_index = Tune.Index.prev_bounded model.selected_index }
      , Cmd.none )
    | Keyboard.Right ->
      ( { model with selected_index = Tune.Index.next_bounded model.selected_index }
      , Cmd.none ))
  | PlayingNote maybe_index -> { model with playing_index = maybe_index }, Cmd.none
  | UrlChange location ->
    let route = locationToRoute location in
    let new_tune =
      match route with
      | Tune n -> n
      | _ -> Tune.default
    in
    { model with route; location }, Cmd.msg (UpdateTune new_tune)
  | UpdateNote (index, new_note) ->
    let new_tune = model.tune |> Tune.update index new_note in
    let play_note _ =
      match new_note with
      | Note.Rest | Note.Hold | Note.Random -> ()
      | _ -> player |. Player.play_no_callback (Note.string_of_note new_note)
    in
    { model with tune = new_tune }, Cmd.call play_note
;;

let view model =
  let open Tea.Html.Attributes in
  let play_pause =
    match model.playing_index with
    | None -> button [ onClick Play ] [ text "Play" ]
    | Some _ -> button [ onClick Stop ] [ text "Stop" ]
  in
  let tune_string = Tune.to_string model.tune in
  let new_hash = "#/tune/" ^ tune_string in
  let share_url =
    match model.location.hash with
    | "" -> model.location.href ^ new_hash
    | hash -> model.location.href |> Js.String.replace hash new_hash
  in
  let frog_note index note =
    let is_playing = model.playing_index = Some index in
    let next_note = Note.next note in
    let previous_note = Note.prev note in
    let next_disabled = Belt.Option.isNone next_note in
    let previous_disabled = Belt.Option.isNone previous_note in
    let update_note n = UpdateNote (index, n) |> onClick in
    let on_next = next_note |. Belt.Option.mapWithDefault noProp update_note in
    let on_previous = previous_note |. Belt.Option.mapWithDefault noProp update_note in
    let is_selected =
      Belt.Option.isNone model.playing_index && index = model.selected_index
    in
    div
      [ class' "ac-frog-container"; onClick (SelectNote index) ]
      [ button [ disabled next_disabled; on_next ] [ text {js|▲|js} ]
      ; FrogSvg.frog_svg note is_selected is_playing
      ; button [ disabled previous_disabled; on_previous ] [ text {js|▼|js} ]
      ]
  in
  div
    []
    [ hr [] []
    ; div
        [ class' "ac-buttons" ]
        [ play_pause
        ; button [ onClick Reset ] [ text "Reset" ]
        ; input' [ class' "ac-share-url"; disabled true; value share_url ] []
        ]
    ; div [] [ FrogSvg.bg_svg model.tune model.selected_index model.playing_index ]
    ; hr [] []
    ; div [ class' "ac-frogs" ] (model.tune |> Tune.mapi frog_note)
    ]
;;

let subscriptions _ = Sub.map keyPressed Keyboard.pressed

let main =
  Tea.Navigation.navigationProgram
    urlChange
    { init; update; view; subscriptions; shutdown = (fun _ -> Cmd.none) }
;;
