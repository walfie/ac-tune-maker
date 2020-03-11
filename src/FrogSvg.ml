open Tea.Html
open Tea.Svg
open Tea.Svg.Attributes
open Note

let frog_svg note is_playing =
  let note_href, note_class, note_text =
    match note with
    | Hold -> "#frog-hold", "frog__text", {js|—|js}
    | Rest -> "#frog-rest", "frog__text", ""
    | Random -> "#frog-random", "frog__text frog__text--large", string_of_note Random
    | other -> "#frog-normal", "frog__text", String.uppercase_ascii (string_of_note other)
  in
  let offset, note_color =
    match note with
    | Rest -> 0, "#aeadae"
    | Hold -> 1, "#b063d5"
    | G -> 2, "#b428d4"
    | A -> 3, "#2689cf"
    | B -> 4, "#0fb8d9"
    | C -> 5, "#30e2a0"
    | D -> 6, "#0cc408"
    | E -> 7, "#88db08"
    | F -> 8, "#f1d009"
    | G' -> 9, "#f5a306"
    | A' -> 10, "#eb6d04"
    | B' -> 11, "#df5506"
    | C' -> 12, "#ce2310"
    | D' -> 13, "#d21e87"
    | E' -> 14, "#c336a0"
    | Random -> 15, "#f35fd2"
  in
  let playing_offset = if is_playing then -50 else 0 in
  let y_offset = string_of_int ((offset * -15) + 225 + playing_offset) in
  svg
    [ class' "ac-frog"; viewBox "0 0 300 500" ]
    [ use [ href note_href; fill note_color; y y_offset ] []
    ; text' [ class' note_class; y y_offset ] [ text note_text ]
    ]
;;
