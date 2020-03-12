module Index = struct
  type t = int

  let min = 0
  let max = 15
  let to_int i = i
  let has_prev i = i >= 0
  let has_next i = i < 16
  let prev i = if has_prev i then Some (i - 1) else None
  let next i = if has_next i then Some (i + 1) else None
  let prev_bounded i = if has_prev i then i - 1 else i
  let next_bounded i = if has_next i then i + 1 else i
end

type t = Note.note list

let length = 16
let get (i : Index.t) (tune : t) : Note.note = Belt.List.getExn tune (Index.to_int i)
let empty : t = List.init 16 (fun _ -> Note.Rest)

(* TODO: Ensure always 16 notes *)
let from_string (str : string) : t =
  let get_or_rest c = Note.from_char c |. Belt.Option.getWithDefault Note.Rest in
  str
  |> Js.String.slice ~from:0 ~to_:length
  |. Js.String.split ""
  |> Array.map get_or_rest
  |> Array.to_list
;;

let to_string (tune : t) : string =
  tune
  |> List.map Note.string_of_note
  |> String.concat ""
  |. Js.String.slice ~from:0 ~to_:length
;;

let default : t =
  let open Note in
  [ G; Hold; A; Hold; B; G; A; B; Hold; G; A; B; Hold; C; Hold; B ]
;;

let update (index : Index.t) (new_value : Note.note) (l : t) =
  let index_as_int = Index.to_int index in
  let replace i old_value = if i = index_as_int then new_value else old_value in
  List.mapi replace l
;;

let mapi (f : Index.t -> Note.note -> 'a) (tune : t) : 'a list = List.mapi f tune
