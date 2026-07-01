# Contributing

Thanks for helping. This is a melos monorepo using Dart pub workspaces.

## Setup

```bash
dart pub global activate melos   # once
flutter pub get                  # resolve the whole workspace from the root
```

## Before you push

```bash
melos run analyze --no-select
melos run test --no-select         # pure-Dart tests (humation, humation_assets_humation_1)
melos run test:flutter --no-select # Flutter tests (humation_flutter)
dart format .
```

The `--no-select` flag runs a script across all matching packages instead of
prompting you to pick one.

All four must pass. CI runs the same.

## Ground rules

- **Determinism is the contract.** Do not change part selection or `fnv1a`. The
  same seed must keep producing the same avatar as the reference engine. The
  golden vector tests guard this.
- **Stay in the SVG subset** the renderer implements (see [AGENTS.md](AGENTS.md)).
  `validateManifest` rejects unsupported features.
- `*.g.dart` is generated. Edit the generator (`tool/embed.mjs`), not the output.
- No em dashes in prose or comments.

## Architecture

See [AGENTS.md](AGENTS.md) for the file map, the public API, and the rendering
invariants.
