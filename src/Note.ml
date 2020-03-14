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
  ; as_str : string
  ; color : string
  ; next : note option
  ; prev : note option
  }

let meta n =
  let m index as_str color next prev = { index; as_str; color; next; prev } in
  match n with
  | Rest -> m 0 "z" "#aeadae" (Some Hold) None
  | Hold -> m 1 "-" "#b063d5" (Some G) (Some Rest)
  | G -> m 2 "g" "#b428d4" (Some A) (Some Hold)
  | A -> m 3 "a" "#2689cf" (Some B) (Some G)
  | B -> m 4 "b" "#0fb8d9" (Some C) (Some A)
  | C -> m 5 "c" "#30e2a0" (Some D) (Some B)
  | D -> m 6 "d" "#0cc408" (Some E) (Some C)
  | E -> m 7 "e" "#88db08" (Some F) (Some D)
  | F -> m 8 "f" "#f1d009" (Some G') (Some E)
  | G' -> m 9 "G" "#f5a306" (Some A') (Some F)
  | A' -> m 10 "A" "#eb6d04" (Some B') (Some G')
  | B' -> m 11 "B" "#df5506" (Some C') (Some A')
  | C' -> m 12 "C" "#ce2310" (Some D') (Some B')
  | D' -> m 13 "D" "#d21e87" (Some E') (Some C')
  | E' -> m 14 "E" "#c336a0" (Some Random) (Some D')
  | Random -> m 15 "q" "#f35fd2" None (Some E')
;;

let next note = (meta note).next
let prev note = (meta note).prev
let color note = (meta note).color
let string_of_note note = (meta note).as_str

let from_char = function
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
  | "q" -> Some Random
  | _ -> None
;;

let notes_of_string str =
  let get_or_rest c = from_char c |. Belt.Option.getWithDefault Rest in
  Js.String.split "" str |> Array.map get_or_rest |> Array.to_list
;;

(* TODO: Ensure 16 notes *)
let string_of_notes notes = notes |> List.map string_of_note |> String.concat ""

let has_next = function
  | Random -> false
  | _ -> true
;;

let has_prev = function
  | Rest -> false
  | _ -> true
;;
