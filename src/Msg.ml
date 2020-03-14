module Direction = struct
  type t =
    | Prev
    | Next
end

type t =
  | Play
  | Stop
  | Reset
  | SelectNote of Tune.Index.t
  | KeyPressed of Keyboard.key
  | PlayingNote of Tune.Index.t option
  | PlayNote of Note.note
  | UpdateNote of Tune.Index.t * Direction.t
  | UpdateTune of Tune.t
  | UrlChange of Web.Location.location
[@@bs.deriving { accessors }]
