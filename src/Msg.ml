type t =
  | Play
  | Stop
  | Reset
  | SelectNote of Tune.Index.t
  | KeyPressed of Keyboard.key
  | PlayingNote of Tune.Index.t option
  | UpdateNote of Tune.Index.t * Note.note
  | UpdateTune of Tune.t
  | UrlChange of Web.Location.location
[@@bs.deriving { accessors }]
