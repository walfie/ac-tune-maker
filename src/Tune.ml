module Index = struct
  type t = int

  let min = 0
  let max = 15
  let to_int i = i
  let has_prev i = i > min
  let has_next i = i < max
  let prev i = if has_prev i then Some (i - 1) else None
  let next i = if has_next i then Some (i + 1) else None
  let prev_bounded i = if has_prev i then i - 1 else i
  let next_bounded i = if has_next i then i + 1 else i
end

type t = Note.note list

let length = 16
let get (i : Index.t) (tune : t) : Note.note = Belt.List.getExn tune (Index.to_int i)
let empty : t = List.init length (fun _ -> Note.Rest)
let random () : t = List.init length (fun _ -> Note.random ())

let from_string (str : string) : t =
  let right_pad = length - String.length str |> max 0 in
  let get_or_rest c = Note.from_char c |. Belt.Option.getWithDefault Note.Rest in
  str
  |> Js.String.slice ~from:0 ~to_:length
  |> Js.String.split ""
  |> Array.map get_or_rest
  |. Array.append (Array.make right_pad Note.Rest)
  |> Array.to_list
;;

let to_string (tune : t) : string =
  tune
  |> List.map (fun n -> (Note.string_of_note n).en)
  |> String.concat ""
  |. Js.String.slice ~from:0 ~to_:length
;;

let default : t = from_string "CECGfGBDCzqzc--z"

let maybe_update_fn (index : Index.t) (f : Note.note -> Note.note option) (l : t) =
  let index_as_int = Index.to_int index in
  let replace i old_value =
    if i = index_as_int
    then f old_value |. Belt.Option.getWithDefault old_value
    else old_value
  in
  List.mapi replace l
;;

let update (index : Index.t) (new_value : Note.note) (l : t) =
  maybe_update_fn index (fun _ -> Some new_value) l
;;

let mapi (f : Index.t -> Note.note -> 'a) (tune : t) : 'a list = List.mapi f tune
