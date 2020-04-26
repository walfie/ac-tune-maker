module Direction = struct
  type t =
    | Prev
    | Next
    | Set of Note.note
end

module Title = struct
  type t =
    { text : string
    ; is_long : bool
    }
end

type t =
  | Play
  | Stop
  | Clear
  | ShowInfo of bool
  | Randomize
  | FrameRendered
  | ExportImage
  | SelectNote of Tune.Index.t option
  | KeyPressed of Keyboard.key
  | PlayingNote of Tune.Index.t option
  | PlayNote of Note.note
  | UpdateNote of Tune.Index.t * Direction.t
  | UpdateTune of Tune.t
  | PromptTitle
  | UpdateTitle of Title.t
  | UrlChange of Web.Location.location
  | SetLanguage of I18n.Lang.t
[@@bs.deriving { accessors }]
