# Animal Crossing Tune Maker

[![Actions Status](https://github.com/walfie/ac-tune-maker/workflows/Main%20workflow/badge.svg?branch=master)](https://github.com/walfie/ac-tune-maker/actions)

A website for making Animal Crossing tunes, written in OCaml with
[Bucklescript-TEA](https://github.com/OvermindDL1/bucklescript-tea).

## Development

- Install dependencies

```
yarn install
```

- Run the development server

```
yarn run dev
```

This will start a dev server on <http://localhost:1234> and auto-reload as
changes are made.

Due to limitations with Parcel, changes made to `.ml` files besides entry point
`App.ml` might not get picked up by the watcher. In this case, you can do a
`touch src/App.ml` to get it to rebuild the Bucklescript files.

Note that the SVG files are written manually and it's not recommended to make
changes to them via a visual editor, since the code depends on certain
classes/elements to exist.

## Production

```
yarn run build
```

Artifacts will be found in the `dist` directory on success.

If deploying to GitHub pages, there's also a `yarn run deploy` script which will
build and push to your `origin/gh-pages` branch (make sure to override the value
in `static/CNAME` if you're using your CNAME).

## Editor setup (Optional)

- Install opam (OCaml Package Manager)

  - <https://opam.ocaml.org/doc/Install.html>

- Install OCaml 4.06.1 (Note: BuckleScript requires 4.06.x)

```
opam switch create 4.06.1
```

- Install OCaml-LSP and ocamlformat

```
opam pin add ocaml-lsp-server https://github.com/ocaml/ocaml-lsp.git
opam install ocaml-lsp-server
```

```
opam install ocamlformat
```

- If you are using VSCode, install
  [OCaml Platform - OCaml Labs](https://marketplace.visualstudio.com/items?itemName=ocamllabs.ocaml-platform);
  otherwise, use any LSP client.
