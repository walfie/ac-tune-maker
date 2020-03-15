module Index : sig
  type t

  val min : t
  val max : t
  val to_int : t -> int
  val has_next : t -> bool
  val has_prev : t -> bool
  val next : t -> t option
  val prev : t -> t option
  val prev_bounded : t -> t
  val next_bounded : t -> t
end

type t

val get : Index.t -> t -> Note.note
val empty : t
val default : t
val length : int
val from_string : string -> t
val to_string : t -> string
val update : Index.t -> Note.note -> t -> t
val maybe_update_fn : Index.t -> (Note.note -> Note.note option) -> t -> t
val mapi : (Index.t -> Note.note -> 'a) -> t -> 'a list
val random : unit -> t
