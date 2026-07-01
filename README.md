# humation_flutter

**Deterministic, hand-drawn kawaii avatars for Flutter and Dart.**
One seed in, one avatar out. No AI, no network, no web view.

This is a Dart and Flutter port of [Humation](https://github.com/humation-labs/humation)
(the TypeScript engine and asset set) and
[humation-swift](https://github.com/humation-labs/humation-swift) (the native
rendering approach). The same seed produces the same avatar on web, native, and
Flutter, because part selection uses the same FNV-1a hash byte-for-byte.

> **Community port.** This is a community-maintained Flutter port by
> [Hark Singh](https://github.com/0xharkirat). It is not affiliated with or
> endorsed by the Humation Labs team. The engine design and the artwork are
> theirs (MIT); see [NOTICE](NOTICE).

```dart
import 'package:humation_flutter/humation_flutter.dart';

// The same user id always renders the same avatar.
HumationAvatar(seed: user.id, size: 96);
```

## Packages

This repository is a melos monorepo with three published packages, split by
concern rather than by platform. Each has a single job.

| Package | Kind | Use it when |
| --- | --- | --- |
| [`humation`](packages/humation) | pure Dart | You want the engine on the server, in a CLI, or in a Dart-only app. It resolves a seed to parts and produces an SVG string. No Flutter. |
| [`humation_assets_humation_1`](packages/humation_assets_humation_1) | pure Dart (data) | You need the actual artwork: the 86-part `humation-1` pack, embedded so it loads with no assets or files. |
| [`humation_flutter`](packages/humation_flutter) | Flutter | You want the `HumationAvatar` widget. This is what most apps install. |

### How they depend on each other

```
        humation  (engine, SVG string, pure Dart)
          ▲   ▲
          │   └────────────────────────────┐
          │                                 │
humation_assets_humation_1 (data)   humation_flutter (widget + CustomPainter)
          ▲                                 │
          └─────────────────────────────────┘
                 humation_flutter bundles the default pack
```

- `humation` depends on nothing. It is the engine.
- `humation_assets_humation_1` depends on `humation` for the manifest model.
- `humation_flutter` depends on both, adds the native renderer and the widget,
  and re-exports the core API so you usually need only one dependency.

### Which one do I add?

- **Flutter app:** add `humation_flutter`. It pulls in the engine and the
  default pack, so `HumationAvatar(seed: ...)` works with zero setup.
- **Dart backend or CLI (no Flutter):** add `humation` and
  `humation_assets_humation_1`, then call `createAvatar(...).toSvg()`.
- **Publishing your own art pack:** depend on `humation` and ship your own
  manifest. Anyone can render it with `humation_flutter`.

### Why three packages instead of one?

So each piece can move on its own. The engine and the widget rarely change, but
new art packs will. Keeping the artwork in its own package means a new pack ships
without touching or re-releasing the engine, and a Dart-only server can pull in
the engine plus a pack without dragging in Flutter. This mirrors the upstream
TypeScript split of `@humation/core`, `@humation/assets-humation-1`, and
`@humation/react`.

Note: this is deliberately **not** a federated plugin (`humation_android`,
`humation_ios`, ...). Federated plugins exist to wrap native device
capabilities. Humation touches none: it is pure computation plus vector drawing,
so one Dart codebase renders identically on every Flutter target.

## Quick start (Flutter)

```yaml
dependencies:
  humation_flutter: ^0.1.0
```

```dart
import 'package:humation_flutter/humation_flutter.dart';

// A seeded avatar.
HumationAvatar(seed: user.id, size: 96);

// Pick parts and colours by name.
HumationAvatar(
  selections: {'head': 'braids', 'body': 'hoodie'},
  colors: {'hair': '#4A3728'},
  size: 96,
);

// Round avatar.
ClipOval(child: HumationAvatar(seed: user.id, size: 40));

// Export a PNG (for sharing, notifications, and so on).
final bytes = await Humation.pngForSeed(user.id, pixels: 256);
```

## Example app

[`packages/humation_flutter/example`](packages/humation_flutter/example) is a
full avatar builder: live preview, seed gallery, per-slot part grid, colour
swatches, and randomize. It is also the source for the web playground on the
docs site.

```bash
cd packages/humation_flutter/example
flutter run            # or: flutter run -d chrome
```

The native platform folders (`android`, `ios`, `macos`) are gitignored;
regenerate them with `flutter create .` inside the example if you need them.

## How it works

Seed to FNV-1a hash to one part per selection slot (head, body, bottom, item,
glasses). Each part is a small SVG in a constrained subset. `humation_flutter`
parses that SVG to vector paths once, then composites and recolours it with a
`CustomPainter`. Six colour slots (`background`, `stroke`, `hair`, `skin`,
`clothes`, `bottom`) are resolved at paint time, so recolouring never re-parses.

Determinism is the contract. The selection hash matches the reference engine
exactly, including for non-ASCII seeds, so a user who set their avatar on the web
sees the same face in your Flutter app.

## Development

```bash
dart pub global activate melos   # once
flutter pub get                          # resolve the workspace
melos run analyze --no-select
melos run test --no-select               # pure-Dart tests
melos run test:flutter --no-select       # Flutter tests
```

The bundled pack is embedded as a base64 Dart constant. To regenerate it from
source, see
[`packages/humation_assets_humation_1/tool/embed.mjs`](packages/humation_assets_humation_1/tool/embed.mjs).

New to the code? Read [AGENTS.md](AGENTS.md) for the map, the invariants, and the
gotchas.

## License

MIT. Engine design and the `humation-1` artwork are from
[humation-labs](https://github.com/humation-labs) (MIT). See [LICENSE](LICENSE)
and [NOTICE](NOTICE).
