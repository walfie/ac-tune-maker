open Binding
open Tea

let set_lang (lang : I18n.Lang.t) =
  let _ = I18n.Lang.to_string lang |> LocalStorage.setItem "lang" in
  Task.succeed ()
;;

let set_document_title (title : string) =
  let _ = Dom.(document |. setTitle {j|$title - Animal Crossing Tune Maker|j}) in
  Task.succeed ()
;;

(* The `text` element in an SVG allows you to force the text to fit in a
 * specified size. However, we only want it constrained when the text is
 * *larger* than the container. To do that, we have to set the text, then check
 * the bounding box to see if the width is larger than our bounds, and if so,
 * add the `textLength` and `lengthAdjust` properties. *)
let get_title_banner_info (new_title : string) =
  let open Dom in
  let elem = document |. querySelectorUnsafe ".js-title-text" in
  let _ = elem |. setInnerHTML new_title in
  let box = elem |. getBBox () in
  let is_long = box.width > 900.0 in
  Task.succeed ({ text = new_title; is_long } : Msg.Title.t)
;;

let update_title (new_title : string) =
  let _ = set_document_title new_title in
  get_title_banner_info new_title
;;

let text_prompt text default =
  Binding.prompt ~text ~default
  |> Js.Nullable.toOption
  |. Belt.Option.getWithDefault default
  |> Task.succeed
;;

let save_svg url filename =
  let open Dom in
  let main_svg = document |. querySelectorUnsafe ".js-svg-main" |. cloneNode true in
  let defs_svg = document |. querySelectorUnsafe ".js-svg-defs" |. cloneNode true in
  let _ = main_svg |. appendChild defs_svg in
  let _ = main_svg |. setAttribute "class" "" in
  let _ =
    (* Generate QR code on a luggage tag *)
    let open QrCodeGenerator in
    let _ =
      main_svg
      |. querySelectorUnsafe ".js-qr-code-tag"
      |. setAttribute "visibility" "visible"
    in
    let qr = QrCodeGenerator.create ~typeNumber:0 ~errorCorrection:"M" in
    let _ = qr |. addData url in
    let _ = qr |. make () in
    let qr_string = qr |. createSvgTag { margin = 2 } in
    let elem = main_svg |. querySelectorUnsafe ".js-qr-code" in
    let _ = elem |. setInnerHTML qr_string in
    let svg = elem |. querySelectorUnsafe "svg" in
    let _ = svg |. setAttribute "width" "300px" in
    let _ = svg |. setAttribute "width" "300px" in
    let _ = svg |. setAttribute "height" "300px" in
    ()
  in
  let _ = SaveSvgAsPng.saveSvgAsPng main_svg filename { scale = 0.5 } in
  Task.succeed ()
;;
