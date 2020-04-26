module Lang : sig
  type t

  val from_string : string -> t
end

type t =
  { en : string
  ; fr : string
  }

val get : Lang.t -> t -> string
