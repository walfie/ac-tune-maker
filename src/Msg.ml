module Direction = struct
  type t =
    | Prev
    | Next
    | Set of Note.note
end

type t =
  | Play
  | Stop
  | Clear
  | Randomize
  | SelectNote of Tune.Index.t option
  | KeyPressed of Keyboard.key
  | PlayingNote of Tune.Index.t option
  | PlayNote of Note.note
  | UpdateNote of Tune.Index.t * Direction.t
  | UpdateTune of Tune.t
  | PromptTitle
  | BoundTitle of bool
  | UpdateTitle of string
  | UrlChange of Web.Location.location
  | AnimationFrame
[@@bs.deriving { accessors }]
