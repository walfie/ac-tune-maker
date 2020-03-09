open Tea
open Tea.App
open Tea.Html
open Tea.Svg
open Tea.Svg.Attributes

type msg = UrlChange of Web.Location.location [@@bs.deriving { accessors }]
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

let update model = function
  | UrlChange location -> { model with route = locationToRoute location }, Cmd.none
;;

let view model =
  let frogs = model.notes |> List.map FrogSvg.frog_svg in
  div [] [ div [ class' "ac-frogs" ] frogs ]
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
