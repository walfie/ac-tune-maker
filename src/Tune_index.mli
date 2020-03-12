type t

val to_int : t -> int
val has_next : t -> bool
val has_prev : t -> bool
val next : t -> t option
val prev : t -> t option
