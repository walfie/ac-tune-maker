# Animal Crossing Tune Maker

A website for making Animal Crossing tunes, written in OCaml with
[Bucklescript-TEA](https://github.com/OvermindDL1/bucklescript-tea).

## Development

This will start a Parcel watcher and listen on http://localhost:1234

```
yarn install
yarn run dev
```

Due to limitations with Parcel, changes made to `.ml` files might not get
picked up by the watcher. In this case you can do a `touch src/App.ml` to
get it to rebuild the Bucklescript files.

Note that the SVG files are written manually and it's not recommended to
make changes to them via a visual editor, since the code depends on
certain classes/elements to exist.

## Production

```
yarn run build
```

Artifacts will be found in the `dist` directory on success.

