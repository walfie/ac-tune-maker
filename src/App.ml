open Tea
open Tea.Html
open Msg
open Binding

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
  ; modal_visible : bool
  ; lang : I18n.Lang.t
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

let default_title = "AC Tune Maker"

let init lang location =
  let route = locationToRoute location in
  ( { route
    ; tune = Tune.default
    ; title = { text = ""; is_long = false }
    ; playing_index = None
    ; awaiting_frame = false
    ; selected_index = None
    ; modal_visible = false
    ; location
    ; lang = I18n.Lang.from_string lang
    }
  , Cmd.batch [ Cmd.msg (UrlChange location) ] )
;;

let share_url model =
  let tune_string = Tune.to_string model.tune in
  let encoded_title = Js.Global.encodeURIComponent model.title.text in
  let new_hash = {j|#/tune/$(tune_string)/$(encoded_title)|j} in
  match model.location.hash with
  | "" -> model.location.href ^ new_hash
  | hash -> model.location.href |> Js.String.replace hash new_hash
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
    let task =
      AppTask.text_prompt "Choose a title" model.title.text
      |> Task.andThen AppTask.update_title
      |> Task.perform Msg.updateTitle
    in
    model, task
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
  | SetLanguage lang -> { model with lang }, Task.ignore (AppTask.set_lang lang)
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
  | ExportImage -> { model with awaiting_frame = true; selected_index = None }, Cmd.none
  | UrlChange location ->
    let route = locationToRoute location in
    let new_tune, new_title =
      match route with
      | Tune (tune, title) -> tune, title
      | _ -> Tune.default, default_title
    in
    let commands =
      [ AppTask.update_title new_title |> Task.perform Msg.updateTitle
      ; Cmd.msg (UpdateTune new_tune)
      ]
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
      | _ -> player |. Player.play_no_callback (Note.string_of_note note).en
    in
    model, Cmd.call play_note
  | ShowInfo modal_visible -> { model with modal_visible }, Cmd.none
  | FrameRendered ->
    let url = share_url model in
    let filename = "tune_" ^ Tune.to_string model.tune ^ ".png" in
    { model with awaiting_frame = false }, Task.ignore (AppTask.save_svg url filename)
;;

let onClickStopPropagation msg =
  onWithOptions
    ~key:""
    "click"
    { defaultOptions with stopPropagation = true }
    (Tea.Json.Decoder.succeed msg)
;;

let modal =
  div
    ~key:""
    [ class' "ac-modal__bg"; onClick (Msg.ShowInfo false) ]
    [ div [ class' "ac-modal__pad-start" ] []
    ; div
        [ class' "ac-modal"; onClickStopPropagation (Msg.ShowInfo true) ]
        [ span
            [ class' "ac-modal__close"; onClickStopPropagation (Msg.ShowInfo false) ]
            [ text {js|×|js} ]
        ; h1 [ class' "ac-modal__title" ] [ text "Animal Crossing Tune Maker" ]
        ; p
            []
            [ text
                "Click a frog and press the up/down triangles to adjust the note. You \
                 can also choose a note from the bottom right, or navigate with the \
                 arrow keys on your keyboard."
            ]
        ; p [] [ text "Tap the banner at the top left to change the tune title." ]
        ; p
            []
            [ text
                "Clicking the `Export` button will save the current tune as a PNG, along \
                 with a QR code containing a link to this page (with the tune \
                 pre-loaded), to make it easier for others to play it."
            ]
        ; div
            [ class' "ac-modal__footer" ]
            [ a
                [ href "https://twitter.com/walfieee/status/1240718100460273665"
                ; target "_blank"
                ]
                [ text "Twitter" ]
            ; text {js|  · |js}
            ; a
                [ href "https://github.com/walfie/ac-tune-maker"; target "_blank" ]
                [ text "GitHub" ]
            ]
        ]
    ; div [ class' "ac-modal__pad-end" ] []
    ]
;;

let view model =
  let play_pause =
    let msg, content =
      match model.playing_index with
      | None -> Play, {js|►|js}
      | Some _ -> Stop, {js|■|js}
    in
    button [ class' "ac-button ac-button--play"; onClick msg ] [ text content ]
  in
  div
    [ class' "ac-container" ]
    [ FrogSvg.bg_svg
        ~tune:model.tune
        ~selected_index:model.selected_index
        ~playing_index:model.playing_index
        ~title:model.title
        ~lang:model.lang
    ; (if model.modal_visible then modal else noNode)
    ; div
        [ class' "ac-controls" ]
        [ input'
            [ class' "ac-share-url"
            ; Html2.Attributes.readonly true
            ; value (share_url model)
            ]
            []
        ; div
            [ class' "ac-buttons" ]
            [ play_pause
            ; button
                [ class' "ac-button ac-button--save"; onClick ExportImage ]
                [ text "Export" ]
            ; button
                [ class' "ac-button ac-button--random"; onClick Randomize ]
                [ text "Random" ]
            ; button
                [ class' "ac-button ac-button--delete"; onClick Clear ]
                [ text "Delete" ]
            ; button
                [ class' "ac-button ac-button--info"; onClick (ShowInfo true) ]
                [ text {js|⋯|js} ]
            ]
        ]
    ]
;;

let subscriptions model =
  Sub.batch
    [ (if model.awaiting_frame
      then AnimationFrame.every (fun _ -> FrameRendered)
      else Sub.none)
    ; Sub.map keyPressed Keyboard.pressed
    ]
;;

let main container lang cachedModel =
  (* Replace the existing shutdown function with one that returns a Promise
   * with the current state of the app, for hot module replacement purposes *)
  let resolveRef = ref None in
  let shutdownPromise =
    Js.Promise.make (fun ~resolve ~reject:_ -> resolveRef := Some resolve)
  in
  let shutdown model =
    let _ =
      match !resolveRef with
      | None -> ()
      | Some resolve -> (resolve model [@bs])
    in
    Cmd.none
  in
  let init =
    match cachedModel with
    | None -> init
    | Some model -> fun _lang _location -> model, Cmd.none
  in
  let run =
    Tea.Navigation.navigationProgram
      urlChange
      { init; update; view; subscriptions; shutdown }
  in
  let app = run container lang in
  let oldShutdown = app##shutdown in
  let newShutdown () =
    let _ = oldShutdown () in
    shutdownPromise
  in
  Js.Obj.assign app [%obj { shutdown = newShutdown }]
;;
