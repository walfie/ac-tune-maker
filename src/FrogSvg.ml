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

let frog_svg
    (lang : I18n.Lang.t)
    (index : Tune.Index.t)
    (note : Note.note)
    (is_large : bool)
    (is_selected : bool)
  =
  let meta = Note.meta note in
  let note_href, note_class, note_text =
    match note with
    | Hold -> "#frog-hold", "frog__text", {js|—|js}
    | Rest -> "#frog-rest", "frog__text", ""
    | Random -> "#frog-random", "frog__text frog__text--large", "?"
    | other -> "#frog-normal", "frog__text", meta.as_str |> I18n.get lang
  in
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
      | _ -> "", 0, false
    in
    use
      [ href href_value
      ; class' "triangle--unshifted clickable"
      ; visibility (if is_visible then "visible" else "hidden")
      ; y_offset + offset |> string_of_int |> y
      ; onClick (Msg.updateNote index direction)
      ]
      []
  in
  let make_triangle direction = if is_selected then triangle direction else noNode in
  g
    [ onClick (Msg.selectNote (Some index)) ]
    [ rect [ class' "frog__clickable-bg clickable" ] []
    ; g
        [ class' "frog clickable"; style {j|transform: translate(0, $(y_offset)px);|j} ]
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
  match input_list |. Belt.List.splitAt index |. Belt.Option.getExn with
  | l1, target :: l2 -> List.concat [ l1; l2; [ target ] ]
  | _ -> input_list
;;

let note_picker
    (lang : I18n.Lang.t)
    (current_note : Note.note option)
    (selected_index : Tune.Index.t)
  =
  let to_elem note =
    let meta = Note.meta note in
    let x_pos = meta.index * 150 in
    let update_note = Msg.updateNote selected_index (Msg.Direction.Set note) in
    let letter = if note = Note.Random then "?" else meta.as_str |> I18n.get lang in
    let current_indicator =
      if current_note = Some note
      then rect [ class' "note_picker__current"; fill meta.color ] []
      else noNode
    in
    g
      [ class' "note_picker__container clickable"
      ; style {j|transform: translate($(x_pos)px, 0)|j}
      ; onClick update_note
      ]
      [ rect
          [ class' "note_picker__note"
          ; fill meta.color
          ; (* Ideally this radius would be specified in CSS, but it doesn't work in Safari *)
            rx "55"
          ]
          []
      ; text' [ class' "note_picker__text" ] [ text letter ]
      ; current_indicator
      ]
  in
  let elems = Note.all |> Js.Array.map to_elem |> Array.to_list in
  g
    [ class' "note_picker" ]
    [ rect [ class' "note_picker__bg"; rx "100" ] []; g [] elems ]
;;

let title_banner (title : Msg.Title.t) =
  g
    ~key:title.text
    [ class' "title_banner--rotated clickable"; onClick Msg.PromptTitle ]
    [ use [ href "#title-banner"; class' "title_banner--unshifted" ] []
    ; text'
        [ class' "title_banner__text"
        ; (if title.is_long then textLength "900" else noProp)
        ; (if title.is_long then lengthAdjust "spacingAndGlyphs" else noProp)
        ]
        [ text title.text ]
    ]
;;

let viewBoxWidth = 3750.0
let viewBoxHeight = 2100.0
let viewBoxString = {j|0 0 $(viewBoxWidth) $(viewBoxHeight)|j}

let bg_svg
    ~(tune : Tune.t)
    ~(selected_index : Tune.Index.t option)
    ~(playing_index : Tune.Index.t option)
    ~(title : Msg.Title.t)
    ~(lang : I18n.Lang.t)
  =
  let current_note = Belt.Option.map selected_index (fun n -> Tune.get n tune) in
  let make_frog index note =
    let is_selected = selected_index = Some index in
    let is_large =
      match playing_index with
      | None -> is_selected
      | Some i -> index = i
    in
    frog_svg lang index note is_large is_selected
  in
  let positioned_frog index frog =
    let x = index mod 8 * 345 in
    let transform_str = {j|transform: translate($(x)px, 0px)|j} in
    let row = if index < 8 then "row__top" else "row__bottom" in
    let uniq = Js.String.make index in
    g ~unique:uniq [ class' row; id uniq ] [ g [ style transform_str ] [ frog ] ]
  in
  let frogs = tune |> Tune.mapi make_frog |> List.mapi positioned_frog in
  let ordered_frogs =
    match selected_index with
    | None -> frogs
    | Some index -> frogs |> move_to_end (Tune.Index.to_int index)
  in
  let note_picker_elem =
    selected_index |. Belt.Option.mapWithDefault noNode (note_picker lang current_note)
  in
  svg
    [ class' "ac-main js-svg-main"; viewBox viewBoxString ]
    [ use
        ~key:""
        [ href "#bg"; onClick (Msg.SelectNote None); pointerEvents "bounding-box" ]
        []
    ; g
        [ class' "bg--shifted" ]
        [ title_banner title
        ; g
            ~key:""
            [ class' "js-qr-code-tag bg--unshifted"; visibility "hidden" ]
            [ use [ href "#qr-code-tag" ] []; g [ class' "js-qr-code qr_code" ] [] ]
        ]
    ; g [ class' "bg--shifted" ] ordered_frogs
    ; g [ class' "bg--shifted" ] [ note_picker_elem ]
    ]
;;
