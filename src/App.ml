open Tea
open Tea.App
open Tea.Html
open Msg

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
    let play_tune (cb : Msg.t Vdom.applicationCallbacks ref) =
      let on_stop () = !cb.enqueue (PlayingNote None) in
      let on_note (args : Player.onNoteArgs) =
        PlayingNote (Some args.index) |> !cb.enqueue
      in
      Player.play player tune_string ~onNote:on_note ~onStop:on_stop
    in
    model, Cmd.call play_tune
  | Stop -> model, Cmd.call (fun _ -> Player.stop player)
  | Reset -> { model with tune = Tune.empty }, Cmd.msg Stop
  | SelectNote index ->
    let cmd =
      if model.playing_index <> None || model.selected_index = index
      then Cmd.none
      else Cmd.msg (model.tune |> Tune.get index |> playNote)
    in
    { model with selected_index = index }, cmd
  | UpdateTune tune -> { model with tune }, Cmd.none
  | KeyPressed key ->
    (match key with
    | Keyboard.Up -> model, Cmd.msg (UpdateNote (model.selected_index, Direction.Next))
    | Keyboard.Down -> model, Cmd.msg (UpdateNote (model.selected_index, Direction.Prev))
    | Keyboard.Left ->
      let index = Tune.Index.prev_bounded model.selected_index in
      model, Cmd.msg (SelectNote index)
    | Keyboard.Right ->
      let index = Tune.Index.next_bounded model.selected_index in
      model, Cmd.msg (SelectNote index))
  | PlayingNote maybe_index -> { model with playing_index = maybe_index }, Cmd.none
  | UrlChange location ->
    let route = locationToRoute location in
    let new_tune =
      match route with
      | Tune n -> n
      | _ -> Tune.default
    in
    { model with route; location }, Cmd.msg (UpdateTune new_tune)
  | UpdateNote (index, direction) ->
    let f =
      match direction with
      | Msg.Direction.Prev -> Note.prev
      | Msg.Direction.Next -> Note.next
    in
    let old_note = model.tune |> Tune.get index |> f in
    (match old_note with
    | None -> model, Cmd.none
    | Some new_note ->
      let new_tune = model.tune |> Tune.update index new_note in
      { model with tune = new_tune }, Cmd.msg (PlayNote new_note))
  | PlayNote note ->
    let play_note _ =
      match note with
      | Note.Rest | Note.Hold -> ()
      | _ -> player |. Player.play_no_callback (Note.string_of_note note)
    in
    model, Cmd.call play_note
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
    let next_prev_button direction f str =
      match f note with
      | Some new_note ->
        button [ disabled false; onClick (UpdateNote (index, direction)) ] [ text str ]
      | None -> button [ disabled true ] [ text str ]
    in
    let is_selected =
      Belt.Option.isNone model.playing_index && index = model.selected_index
    in
    div
      [ class' "ac-frog-container"; onClick (SelectNote index) ]
      [ next_prev_button Direction.Next Note.next {js|▲|js}
      ; FrogSvg.frog_svg note is_selected is_playing
      ; next_prev_button Direction.Prev Note.prev {js|▼|js}
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
