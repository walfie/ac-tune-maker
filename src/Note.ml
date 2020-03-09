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

let char_of_note = function
  | Rest -> 'z'
  | Hold -> '-'
  | G -> 'g'
  | A -> 'a'
  | B -> 'b'
  | C -> 'c'
  | D -> 'd'
  | E -> 'e'
  | F -> 'f'
  | G' -> 'G'
  | A' -> 'A'
  | B' -> 'B'
  | C' -> 'C'
  | D' -> 'D'
  | E' -> 'E'
  | Random -> '?'
;;

let string_of_note note = char_of_note note |> String.make 1

let note_of_char = function
  | 'z' -> Some Rest
  | '-' -> Some Hold
  | 'g' -> Some G
  | 'a' -> Some A
  | 'b' -> Some B
  | 'c' -> Some C
  | 'd' -> Some D
  | 'e' -> Some E
  | 'f' -> Some F
  | 'G' -> Some G'
  | 'A' -> Some A'
  | 'B' -> Some B'
  | 'C' -> Some C'
  | 'D' -> Some D'
  | 'E' -> Some E'
  | '?' -> Some Random
  | _ -> None
;;

let next_note = function
  | Rest -> Some Hold
  | Hold -> Some G
  | G -> Some A
  | A -> Some B
  | B -> Some C
  | C -> Some D
  | D -> Some E
  | E -> Some F
  | F -> Some G'
  | G' -> Some A'
  | A' -> Some B'
  | B' -> Some C'
  | C' -> Some D'
  | D' -> Some E'
  | E' -> Some Random
  | Random -> None
;;

let previous_note = function
  | Rest -> None
  | Hold -> Some Rest
  | G -> Some Hold
  | A -> Some G
  | B -> Some A
  | C -> Some B
  | D -> Some C
  | E -> Some D
  | F -> Some E
  | G' -> Some F
  | A' -> Some G'
  | B' -> Some A'
  | C' -> Some B'
  | D' -> Some C'
  | E' -> Some D'
  | Random -> Some E'
;;
