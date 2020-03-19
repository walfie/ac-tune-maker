# Animal Crossing Tune Maker

A website for making Animal Crossing tunes, written in OCaml with
[Bucklescript-TEA](https://github.com/OvermindDL1/bucklescript-tea).

## Development

```
yarn install
yarn run dev
```

This will start a dev server on http://localhost:1234 and auto-reload as
changes are made.

Due to limitations with Parcel, changes made to `.ml` files besides the
entrypoint `App.ml` might not get picked up by the watcher. In this case you
can do a `touch src/App.ml` to get it to rebuild the Bucklescript files.

Note that the SVG files are written manually and it's not recommended to
make changes to them via a visual editor, since the code depends on
certain classes/elements to exist.

## Production

```
yarn run build
```

Artifacts will be found in the `dist` directory on success.

If deploying to GitHub pages, there's also a `yarn run deploy` script which
will build and push to your `origin/gh-pages` branch (make sure to override the
value in `static/CNAME` if you're using your own CNAME).

