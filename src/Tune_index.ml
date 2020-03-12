type t = int

let to_int i = i
let has_prev i = i >= 0
let has_next i = i < 16
let prev i = if has_prev i then Some (i - 1) else None
let next i = if has_next i then Some (i + 1) else None
