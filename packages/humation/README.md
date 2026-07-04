# humation

[![pub package](https://img.shields.io/pub/v/humation.svg)](https://pub.dev/packages/humation)

**Deterministic hand-drawn kawaii avatar engine for Dart.**
Pure Dart, no Flutter, no network, no AI. One seed in, one avatar out.

This is the engine. It resolves a seed to a fixed set of parts and produces an
SVG string or structured render data. For a Flutter widget, use
[`humation_flutter`](https://pub.dev/packages/humation_flutter). For the ready
made artwork, use
[`humation_assets_humation_1`](https://pub.dev/packages/humation_assets_humation_1).

Part selection is byte-identical to the reference
[Humation](https://github.com/humation-labs/humation) engine (FNV-1a over UTF-16
code units), so the same seed yields the same avatar on web, native, and Flutter.

> **Community port** by [Hark Singh](https://github.com/0xharkirat), not
> affiliated with the Humation Labs team. Engine design is from
> [humation-labs](https://github.com/humation-labs) (MIT).

## Install

```yaml
dependencies:
  humation: ^0.1.0
  humation_assets_humation_1: ^0.1.0   # the default artwork
```

## Usage

```dart
import 'package:humation/humation.dart';
import 'package:humation_assets_humation_1/humation_assets_humation_1.dart';

final manifest = humation1Manifest;

// Seed to a self-contained SVG string.
final svg = createAvatar(
  manifest,
  const CreateAvatarOptions(seed: 'felix'),
).toSvg();

// Pick parts and colours by name.
final custom = createAvatar(
  manifest,
  const CreateAvatarOptions(
    selections: {'head': 'braids', 'body': 'hoodie'},
    colors: {'hair': '#123456'},
  ),
).toSvg();
```

The SVG uses `var(--hm-*)` colour variables with the values set on the root
element, so it recolours through CSS in any viewer that supports custom
properties. Serve it, write it to a file, or hand it to a browser.

## API

- `createAvatar(manifest, options)` returns a `HumationAvatar` with `toSvg()`,
  `toDataUri()`, `toJson()`, and `toRenderData()`.
- `resolveAvatarState(manifest, options)` returns the resolved `AvatarState`
  (concrete part per slot, concrete hex per colour slot).
- `resolvePartId(input, manifest, slotId: ...)` resolves ids, aliases, and
  slot-scoped names.
- `getPartsForSlot` / `getPartsForUiGroup` list parts for pickers.
- `validateManifest(manifest)` checks slot references and flags unsupported
  path commands (arcs, quadratics). An empty result means those checks passed;
  it is not a full SVG parse.
- `fnv1a` and `normalizeHex` are the shared primitives.

`toRenderData()` returns an `AvatarRenderData` (view box, background, colours,
and ordered fragments). This is what native renderers such as `humation_flutter`
consume.

## License

MIT. Engine design is from
[humation-labs/humation](https://github.com/humation-labs/humation) (MIT).
