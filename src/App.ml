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
  ; selected_index : Tune.Index.t option
  }

let locationToRoute location =
  match location.Web.Location.hash |> String.split_on_char '/' |> List.tl with
  | [ "tune"; tune ] -> Tune (Tune.from_string tune)
  | _ -> Index
;;

let init () location =
  let route = locationToRoute location in
  ( { route; tune = Tune.default; playing_index = None; selected_index = None; location }
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
  | Clear -> { model with tune = Tune.empty }, Cmd.msg Stop
  | Randomize -> model, Cmd.msg (Tune.random () |> Msg.updateTune)
  | SelectNote None -> { model with selected_index = None }, Cmd.none
  | SelectNote (Some index) ->
    let cmd =
      if model.playing_index <> None || model.selected_index = Some index
      then Cmd.none
      else Cmd.msg (model.tune |> Tune.get index |> playNote)
    in
    { model with selected_index = Some index }, cmd
  | UpdateTune tune -> { model with tune }, Cmd.msg Stop
  | KeyPressed key ->
    let maybe_update_note dir =
      match model.selected_index with
      | Some index -> Cmd.msg (UpdateNote (index, dir))
      | None -> Cmd.none
    in
    let maybe_update_index default f =
      match model.selected_index with
      | Some selected -> Cmd.msg (SelectNote (f selected))
      | None -> Cmd.msg (SelectNote (Some default))
    in
    (match key with
    | Keyboard.Up -> model, maybe_update_note Direction.Next
    | Keyboard.Down -> model, maybe_update_note Direction.Prev
    | Keyboard.Left -> model, maybe_update_index Tune.Index.max Tune.Index.prev
    | Keyboard.Right -> model, maybe_update_index Tune.Index.min Tune.Index.next)
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
      | Msg.Direction.Set n -> fun _ -> Some n
    in
    let maybe_new_note = model.tune |> Tune.get index |> f in
    (match maybe_new_note with
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
    let msg, content =
      match model.playing_index with
      | None -> Play, {js|▶|js}
      | Some _ -> Stop, {js|■|js}
    in
    button [ class' "ac-button"; onClick msg ] [ text content ]
  in
  let tune_string = Tune.to_string model.tune in
  let new_hash = "#/tune/" ^ tune_string in
  let share_url =
    match model.location.hash with
    | "" -> model.location.href ^ new_hash
    | hash -> model.location.href |> Js.String.replace hash new_hash
  in
  div
    []
    [ FrogSvg.bg_svg model.tune model.selected_index model.playing_index
    ; div
        [ class' "ac-buttons" ]
        [ play_pause
        ; button [ class' "ac-button"; onClick Clear ] [ text "Clear" ]
        ; button [ class' "ac-button"; onClick Randomize ] [ text "Random" ]
        ; input' [ class' "ac-share-url"; disabled true; value share_url ] []
        ]
    ]
;;

let subscriptions _ = Sub.map keyPressed Keyboard.pressed

let main =
  Tea.Navigation.navigationProgram
    urlChange
    { init; update; view; subscriptions; shutdown = (fun _ -> Cmd.none) }
;;
