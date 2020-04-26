module Lang = struct
  type t =
    | En
    | Fr

  let from_string s =
    match Js.String.split "-" s |. Js.Array.unsafe_get 0 with
    | "fr" -> Fr
    | _ -> En
  ;;

  let to_string = function
    | Fr -> "fr"
    | En -> "en"
  ;;
end

type t =
  { en : string
  ; fr : string
  }

let get lang v =
  match lang with
  | Lang.En -> v.en
  | Lang.Fr -> v.fr
;;
