module Lang : sig
  type t =
    | En
    | Fr

  val from_string : string -> t
  val to_string : t -> string
end

type t =
  { en : string
  ; fr : string
  }

val get : Lang.t -> t -> string
