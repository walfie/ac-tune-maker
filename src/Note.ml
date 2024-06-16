type note =
  | Rest
  | Hold
  | G
  | A
  | B
  | C
  | D
  | E
  | F
  | G'
  | A'
  | B'
  | C'
  | D'
  | E'
  | Random

type meta =
  { index : int
  ; as_str : I18n.t
  ; color : string
  ; next : note option
  ; prev : note option
  }

let all = [| Rest; Hold; G; A; B; C; D; E; F; G'; A'; B'; C'; D'; E'; Random |]
let random () = Js.Array.length all |> Js.Math.random_int 0 |> Js.Array.unsafe_get all

let meta n =
  let m index (en, fr) color next prev =
    let open I18n in
    { index; as_str = { en; fr }; color; next; prev }
  in
  match n with
  | Rest -> m 0 ("z", "z") "#aeadae" (Some Hold) None
  | Hold -> m 1 ("-", "-") "#b063d5" (Some G) (Some Rest)
  | G -> m 2 ("g", "sol") "#b428d4" (Some A) (Some Hold)
  | A -> m 3 ("a", "la") "#2689cf" (Some B) (Some G)
  | B -> m 4 ("b", "si") "#0fb8d9" (Some C) (Some A)
  | C -> m 5 ("c", "do") "#30e2a0" (Some D) (Some B)
  | D -> m 6 ("d", {js|ré|js}) "#0cc408" (Some E) (Some C)
  | E -> m 7 ("e", "mi") "#88db08" (Some F) (Some D)
  | F -> m 8 ("f", "fa") "#f1d009" (Some G') (Some E)
  | G' -> m 9 ("G", "Sol") "#f5a306" (Some A') (Some F)
  | A' -> m 10 ("A", "La") "#eb6d04" (Some B') (Some G')
  | B' -> m 11 ("B", "Si") "#df5506" (Some C') (Some A')
  | C' -> m 12 ("C", "Do") "#ce2310" (Some D') (Some B')
  | D' -> m 13 ("D", {js|Ré|js}) "#d21e87" (Some E') (Some C')
  | E' -> m 14 ("E", "Mi") "#c336a0" (Some Random) (Some D')
  | Random -> m 15 ("q", "q") "#f35fd2" None (Some E')
;;

let next note = (meta note).next
let prev note = (meta note).prev
let color note = (meta note).color
let string_of_note note = (meta note).as_str

let of_char = function
  | "z" -> Some Rest
  | "-" -> Some Hold
  | "g" -> Some G
  | "a" -> Some A
  | "b" -> Some B
  | "c" -> Some C
  | "d" -> Some D
  | "e" -> Some E
  | "f" -> Some F
  | "G" -> Some G'
  | "A" -> Some A'
  | "B" -> Some B'
  | "C" -> Some C'
  | "D" -> Some D'
  | "E" -> Some E'
  | "q" | "?" -> Some Random
  | _ -> None
;;

let notes_of_string str =
  let get_or_rest c = of_char c |. Belt.Option.getWithDefault Rest in
  Js.String.split "" str |> Array.map get_or_rest |> Array.to_list
;;

let has_next = function
  | Random -> false
  | _ -> true
;;

let has_prev = function
  | Rest -> false
  | _ -> true
;;
