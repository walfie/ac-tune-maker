open Tea
open Tea.App
open Tea.Html
open Tea.Html.Attributes

type msg =
  | PreviousNote of int
  | NextNote of int
  | UrlChange of Web.Location.location
[@@bs.deriving { accessors }]

type route = Index

type state =
  { route : route
  ; notes : Note.note list
  }

let locationToRoute location =
  match location.Web.Location.hash |> String.split_on_char '/' |> List.tl with
  | _ -> Index
;;

let init () location =
  ( { route = locationToRoute location; notes = List.init 16 (fun _ -> Note.Rest) }
  , Cmd.none )
;;

let update_at_index f index l =
  let maybe_f x =
    match f x with
    | Some x' -> x'
    | None -> x
  in
  let maybe_replace i x = if i = index then maybe_f x else x in
  List.mapi maybe_replace l
;;

let update model = function
  | UrlChange location -> { model with route = locationToRoute location }, Cmd.none
  | PreviousNote index ->
    { model with notes = update_at_index Note.previous_note index model.notes }, Cmd.none
  | NextNote index ->
    { model with notes = update_at_index Note.next_note index model.notes }, Cmd.none
;;

let view model =
  let frog_note index note =
    let has_next = Note.has_next note in
    let has_previous = Note.has_previous note in
    let on_next = onClick (NextNote index) in
    let on_previous = onClick (PreviousNote index) in
    div
      [ class' "ac-frog-container" ]
      [ button [ (not has_next) |> disabled; on_next ] [ text {js|▲|js} ]
      ; FrogSvg.frog_svg note
      ; button [ (not has_previous) |> disabled; on_previous ] [ text {js|▼|js} ]
      ]
  in
  div [] [ div [ class' "ac-frogs" ] (model.notes |> List.mapi frog_note) ]
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
