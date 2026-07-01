# humation_flutter example

A self-contained avatar builder: live preview, seed gallery, per-slot part grid,
colour swatches, and randomize. It uses only `humation_flutter`, and it is the
app embedded as the playground on the docs site.

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
