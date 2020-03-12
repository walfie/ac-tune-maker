type t

val get : Tune_index.t -> t -> Note.note
val length : int
val empty : t
val from_string : string -> t
val to_string : t -> string
val default : t
val update : Tune_index.t -> Note.note -> t -> t
