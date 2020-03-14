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
  let y_offset = meta.index * -15 in
  let y_offset_prop = y (string_of_int y_offset) in
  let hand =
    if is_selected then use ~unique:"hand" [ href "#hand"; y_offset_prop ] [] else noNode
  in
  let triangle direction =
    let href_value, offset, is_visible =
      match direction with
      | Msg.Direction.Prev -> "#triangle-down", 290, Note.has_prev note
      | Msg.Direction.Next -> "#triangle-up", -180, Note.has_next note
    in
    use
      [ href href_value
      ; class' "triangle--unshifted"
      ; display (if is_visible then "inline" else "none")
      ; (* The 6/5 is a hack to counter the `scale(1.2)` on the `frog--large` class *)
        (y_offset * 6 / 5) + offset |> string_of_int |> y
      ; onClick (Msg.updateNote index direction)
      ]
      []
  in
  let make_triangle direction = if is_selected then triangle direction else noNode in
  g
    [ class' "clickable"; onClick (Msg.SelectNote index) ]
    [ rect [ class' "frog__clickable-bg" ] []
    ; g
        [ classes [ "frog--large", is_large ] ]
        [ g
            [ class' "frog--unshifted" ]
            [ use [ href note_href; fill meta.color; y_offset_prop ] []
            ; text' [ class' note_class; y_offset_prop ] [ text note_text ]
            ]
        ]
    ; make_triangle Msg.Direction.Prev
    ; make_triangle Msg.Direction.Next
    ; hand
    ]
;;

(* SVGs don't use z-index, so we have to depend on ordering of elements to
 * determine what shows up at the top layer *)
let move_to_end index input_list =
  let l1, target :: l2 = input_list |. Belt.List.splitAt index |. Belt.Option.getExn in
  List.concat [ l1; l2; [ target ] ]
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
  let positioned_frog index frog =
    let x = index mod 8 * 345 in
    let transform_str = {j|transform: translate($(x)px, 0px)|j} in
    let row = if index < 8 then "row__top" else "row__bottom" in
    let uniq = {j|note$(index)|j} in
    g ~unique:uniq [ class' row; id uniq ] [ g [ style transform_str ] [ frog ] ]
  in
  let frogs =
    tune
    |> Tune.mapi make_frog
    |> List.mapi positioned_frog
    |> move_to_end (Tune.Index.to_int selected_index)
  in
  svg
    [ viewBox "0 0 3500 2050" ]
    [ use [ href "#bg" ] []; g [ class' "bg--shifted" ] frogs ]
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
