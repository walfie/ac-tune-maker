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

let frog_svg index note is_large is_selected =
  let note_href, note_class, note_text =
    match note with
    | Hold -> "#frog-hold", "frog__text", {js|—|js}
    | Rest -> "#frog-rest", "frog__text", ""
    | Random -> "#frog-random", "frog__text frog__text--large", "?"
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
      | Msg.Direction.Prev -> "#triangle-down", 240, Note.has_prev note
      | Msg.Direction.Next -> "#triangle-up", -215, Note.has_next note
    in
    use
      [ href href_value
      ; class' "triangle--unshifted"
      ; display (if is_visible then "inline" else "none")
      ; y_offset + offset |> string_of_int |> y
      ; onClick (Msg.updateNote index direction)
      ]
      []
  in
  let make_triangle direction = if is_selected then triangle direction else noNode in
  g
    [ class' "clickable"; onClick (Msg.SelectNote index) ]
    [ rect [ class' "frog__clickable-bg" ] []
    ; g
        [ class' "frog"; style {j|transform: translate(0, $(y_offset)px);|j} ]
        [ g
            [ classes [ "frog--large", is_large ] ]
            [ g
                [ class' "frog--unshifted" ]
                [ use [ href note_href; fill meta.color ] []
                ; text' [ class' note_class ] [ text note_text ]
                ]
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

let note_picker current_note selected_index =
  let to_elem note =
    let meta = Note.meta note in
    let x_pos = meta.index * 150 in
    let update_note = Msg.updateNote selected_index (Msg.Direction.Set note) in
    let current_indicator =
      if current_note = note
      then rect [ class' "note_picker__current"; fill meta.color ] []
      else noNode
    in
    let letter =
      match note with
      | Note.Random -> "?"
      | _ -> meta.as_str
    in
    g
      ~unique:letter
      [ class' "note_picker__circle clickable"
      ; style {j|transform: translate($(x_pos)px, 0)|j}
      ; onClick update_note
      ]
      [ circle [ fill meta.color; r "70" ] []
      ; text' [ class' "note_picker__text" ] [ text letter ]
      ; current_indicator
      ]
  in
  let elems = Note.all |> Js.Array.map to_elem |> Array.to_list in
  g [ class' "note_picker" ] [ rect [ class' "note_picker__bg" ] []; g [] elems ]
;;

let bg_svg tune selected_index playing_index =
  let current_note = Tune.get selected_index tune in
  let make_frog index note =
    let is_large =
      match playing_index with
      | None -> index = selected_index
      | Some i -> index = i
    in
    frog_svg index note is_large (selected_index = index)
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
    [ class' "ac-main"; viewBox "0 0 3500 2050" ]
    [ use [ href "#bg" ] []
    ; g [ class' "bg--shifted" ] frogs
    ; g [ class' "bg--shifted" ] [ note_picker current_note selected_index ]
    ]
;;
