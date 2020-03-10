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
  | UrlChange location -> { model with route = locationToRoute location }, Cmd.none
  | UpdateNote (index, value) ->
    { model with notes = update_at_index model.notes index value }, Cmd.none
;;

module Option = struct
  let is_some = function
    | Some _ -> true
    | None -> false
  ;;

  let fold default f = function
    | Some x -> f x
    | None -> default
  ;;
end

let view model =
  let frog_note index note =
    let next_note = Note.next_note note in
    let previous_note = Note.previous_note note in
    let has_next = Option.is_some next_note in
    let has_previous = Option.is_some previous_note in
    let update_note n = onClick (UpdateNote (index, n)) in
    let on_next = Option.fold noProp update_note next_note in
    let on_previous = Option.fold noProp update_note previous_note in
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
