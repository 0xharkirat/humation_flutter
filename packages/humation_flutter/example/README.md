# humation_flutter example

A minimal usage demo: a seeded avatar and a custom selections-and-colours
avatar, side by side. Uses only `humation_flutter`.

For a full avatar builder (live preview, part grid, colour swatches,
randomize), see
[`playground/`](https://github.com/0xharkirat/humation_flutter/tree/main/playground)
in the repo, the app behind the web playground on the docs site.

```bash
flutter run            # a connected device or simulator
flutter run -d chrome  # in the browser
```

## Platform folders

The `web/` folder is committed so the playground builds from a clean clone. The
native folders (`android`, `ios`, `macos`) are gitignored to keep the repo
light. Regenerate any you need with:

```bash
flutter create . --platforms=android,ios,macos
```
