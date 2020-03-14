open Tea.Html
open Tea.Svg
open Tea.Svg.Attributes
open Note

let classes classes =
  classes
  |> List.filter (fun (_fst, snd) -> snd)
  |> List.map (fun (fst, _snd) -> fst)
  |> String.concat " "
  |> class'
;;

let frog_svg' index note is_large is_selected =
  let note_href, note_class, note_text =
    match note with
    | Hold -> "#frog-hold", "frog__text", {js|—|js}
    | Rest -> "#frog-rest", "frog__text", ""
    | Random -> "#frog-random", "frog__text frog__text--large", string_of_note Random
    | other -> "#frog-normal", "frog__text", String.uppercase_ascii (string_of_note other)
  in
  let meta = Note.meta note in
  let y_offset = string_of_int (meta.index * -15) in
  let hand =
    if is_selected then use ~unique:"hand" [ href "#hand"; y y_offset ] [] else noNode
  in
  g
    [ onClick (Msg.SelectNote index) ]
    [ g
        [ classes [ "frog--large", is_large ] ]
        [ g
            [ class' "frog--unshifted" ]
            [ use [ href note_href; fill meta.color; y y_offset ] []
            ; text' [ class' note_class; y y_offset ] [ text note_text ]
            ]
        ]
    ; hand
    ]
;;

let bg_svg tune selected_index playing_index =
  let make_frog index note =
    let is_large =
      match playing_index with
      | None -> index = selected_index
      | Some i -> index = i
    in
    frog_svg' index note is_large (selected_index = index)
  in
  let top_row, bottom_row =
    tune |> Tune.mapi make_frog |. Belt.List.splitAt 8 |. Belt.Option.getExn
  in
  let positioned_frog index frog =
    let x = index * 345 in
    g [ style {j|transform: translate($(x)px, 0px)|j} ] [ frog ]
  in
  svg
    [ viewBox "0 0 3500 2050" ]
    [ use [ href "#bg" ] []
    ; g
        [ class' "bg--shifted" ]
        (* Reversing the order here so the top left one gets rendered last,
           to prevent overlaps. SVGs don't have z-indexes *)
        [ g [ class' "row__bottom" ] (bottom_row |> List.mapi positioned_frog |> List.rev)
        ; g [ class' "row__top" ] (top_row |> List.mapi positioned_frog |> List.rev)
        ]
    ]
;;

let frog_svg note is_selected is_playing =
  let note_href, note_class, note_text =
    match note with
    | Hold -> "#frog-hold", "frog__text", {js|—|js}
    | Rest -> "#frog-rest", "frog__text", ""
    | Random -> "#frog-random", "frog__text frog__text--large", string_of_note Random
    | other -> "#frog-normal", "frog__text", String.uppercase_ascii (string_of_note other)
  in
  let meta = Note.meta note in
  let playing_offset = if is_playing then -50 else 0 in
  let y_offset = string_of_int ((meta.index * -15) + 225 + playing_offset) in
  svg
    [ classes [ "ac-frog", true; "ac-frog--selected", is_selected ]
    ; viewBox "0 0 300 500"
    ]
    [ use [ href note_href; fill meta.color; y y_offset ] []
    ; text' [ class' note_class; y y_offset ] [ text note_text ]
    ]
;;
