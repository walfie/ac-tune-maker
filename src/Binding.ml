module Player = struct
  type onNoteArgs =
    { index : Tune.Index.t
    ; note : string
    }

  type onNote = onNoteArgs -> unit
  type onStop = unit -> unit
  type player

  external create : unit -> player = "default" [@@bs.module "./player"] [@@bs.new]
  external stop : player -> unit = "stop" [@@bs.send]

  external play : player -> string -> onNote:onNote -> onStop:onStop -> unit = "play"
    [@@bs.send]

  external play_no_callback : player -> string -> unit = "play" [@@bs.send]
end

module Dom = struct
  type document
  type element

  type bbox =
    { width : float
    ; height : float
    }

  external document : document = "document" [@@bs.val]

  (* This could technically return null, but we're only using this for `.js-title-text` *)
  external querySelector : document -> string -> element = "querySelector" [@@bs.send]

  external createElementNS : document -> string -> string -> element = "createElementNS"
    [@@bs.send]

  external setInnerHTML : element -> string -> unit = "innerHTML" [@@bs.set]
  external getBBox : element -> unit -> bbox = "getBBox" [@@bs.send]
  external cloneNode : element -> bool -> element = "cloneNode" [@@bs.send]
  external appendChild : element -> element -> unit = "appendChild" [@@bs.send]
  external setAttribute : element -> string -> string -> unit = "setAttribute" [@@bs.send]
end

module SaveSvgAsPng = struct
  type options = { scale : float }

  external saveSvgAsPng : Dom.element -> string -> options -> unit = "saveSvgAsPng"
    [@@bs.module "save-svg-as-png"] [@@bs.new]
end

external prompt : text:string -> default:string -> string Js.Nullable.t = "prompt"
  [@@bs.val] [@@bs.scope "window"]
