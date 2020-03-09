open Tea
open Tea.App
open Tea.Html
open Tea.Svg
open Tea.Svg.Attributes

type msg = UrlChange of Web.Location.location [@@bs.deriving { accessors }]
type route = Index
type state = { route : route }

let locationToRoute location =
  match location.Web.Location.hash |> String.split_on_char '/' |> List.tl with
  | _ -> Index
;;

let init () location = { route = locationToRoute location }, Cmd.none

let update model = function
  | UrlChange location -> { route = locationToRoute location }, Cmd.none
;;

let view model =
  div
    []
    [ FrogSvg.frog_svg Note.Random
    ; FrogSvg.frog_svg Note.Rest
    ; FrogSvg.frog_svg Note.G
    ; FrogSvg.frog_svg Note.D
    ; FrogSvg.frog_svg Note.Hold
    ; FrogSvg.frog_svg Note.E'
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
