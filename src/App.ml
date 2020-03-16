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

external prompt : text:string -> default:string -> string Js.Nullable.t = "prompt"
  [@@bs.val] [@@bs.scope "window"]

let player = Player.create ()

type route =
  | Index
  | Tune of Tune.t * string

type state =
  { route : route
  ; location : Web.Location.location
  ; title : Msg.Title.t
  ; tune : Tune.t
  ; playing_index : Tune.Index.t option
  ; selected_index : Tune.Index.t option
  ; awaiting_frame : bool
  }

let locationToRoute location =
  match location.Web.Location.hash |> String.split_on_char '/' |> List.tl with
  | [ "tune"; tune; title ] ->
    Tune (Tune.from_string tune, Js.Global.decodeURIComponent title)
  | _ -> Index
;;

let update_at_index l index new_value =
  let replace i old_value = if i = index then new_value else old_value in
  List.mapi replace l
;;

module Document = struct
  type document
  type element

  type bbox =
    { width : float
    ; height : float
    }

  external document : document = "" [@@bs.val]

  (* This could technically return null, but we're only using this for `.js-title-text` *)
  external querySelector : document -> string -> element = "" [@@bs.send]
  external setInnerHTML : element -> string -> unit = "innerHTML" [@@bs.set]
  external getBBox : element -> unit -> bbox = "getBBox" [@@bs.send]
end

(* The `text` element in an SVG allows you to force the text to fit in a
 * specified size. However, we only want it constrained when the text is
 * *larger* than the container. To do that, we have to set the text, then check
 * the bounding box to see if the width is larger than our bounds, and if so,
 * add the `textLength` and `lengthAdjust` properties. *)
let update_title_call (new_title : string) (cb : Msg.t Vdom.applicationCallbacks ref) =
  let open Document in
  let elem = document |. querySelector ".js-title-text" in
  let _ = elem |. setInnerHTML new_title in
  let box = elem |. getBBox () in
  let is_long = box.width > 900.0 in
  Msg.UpdateTitle { text = new_title; is_long } |> !cb.enqueue
;;

let default_title = "Default Tune"

let init () location =
  let route = locationToRoute location in
  ( { route
    ; tune = Tune.default
    ; title = { text = ""; is_long = false }
    ; playing_index = None
    ; awaiting_frame = true
    ; selected_index = Some Tune.Index.min
    ; location
    }
  , Cmd.batch [ Cmd.msg (UrlChange location) ] )
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
  | PromptTitle ->
    let call_fn (cb : Msg.t Vdom.applicationCallbacks ref) =
      let new_title = prompt ~text:"Choose a title" ~default:model.title.text in
      match Js.Nullable.toOption new_title with
      | Some title -> update_title_call title cb
      | None -> ()
    in
    model, Cmd.call call_fn
  | UpdateTitle title -> { model with title }, Cmd.none
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
    let new_tune, new_title =
      match route with
      | Tune (tune, title) -> tune, title
      | _ -> Tune.default, default_title
    in
    let commands =
      [ Cmd.call (update_title_call new_title); Cmd.msg (UpdateTune new_tune) ]
    in
    { model with route; location }, Cmd.batch commands
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
    button [ class' "ac-button ac-button--play"; onClick msg ] [ text content ]
  in
  let tune_string = Tune.to_string model.tune in
  let encoded_title = Js.Global.encodeURIComponent model.title.text in
  let new_hash = {j|#/tune/$(tune_string)/$(encoded_title)|j} in
  let share_url =
    match model.location.hash with
    | "" -> model.location.href ^ new_hash
    | hash -> model.location.href |> Js.String.replace hash new_hash
  in
  div
    [ class' "ac-container" ]
    [ FrogSvg.bg_svg
        ~tune:model.tune
        ~selected_index:model.selected_index
        ~playing_index:model.playing_index
        ~title:model.title
    ; div
        [ class' "ac-controls" ]
        [ input' [ class' "ac-share-url"; disabled true; value share_url ] []
        ; div
            [ class' "ac-buttons" ]
            [ play_pause
            ; button
                [ class' "ac-button ac-button--random"; onClick Randomize ]
                [ text "Random" ]
            ; button
                [ class' "ac-button ac-button--delete"; onClick Clear ]
                [ text "Clear" ]
            ]
        ]
    ]
;;

let subscriptions model = Sub.map keyPressed Keyboard.pressed

let main =
  Tea.Navigation.navigationProgram
    urlChange
    { init; update; view; subscriptions; shutdown = (fun _ -> Cmd.none) }
;;
