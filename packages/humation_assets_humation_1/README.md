# humation_assets_humation_1

[![pub package](https://img.shields.io/pub/v/humation_assets_humation_1.svg)](https://pub.dev/packages/humation_assets_humation_1)

The **humation-1** asset pack for the [Humation](https://pub.dev/packages/humation)
avatar engine: 86 hand-drawn SVG parts plus the manifest that describes them.

The pack is embedded as a base64 Dart constant, so it needs no asset bundling and
no file loading. It works on the server, on the web, and in Flutter alike.

> **Community port** by [Hark Singh](https://github.com/0xharkirat), not
> affiliated with the Humation Labs team. The artwork is from
> [humation-labs](https://github.com/humation-labs) (MIT).

## Install

```yaml
dependencies:
  humation: ^0.1.0
  humation_assets_humation_1: ^0.1.0
```

Flutter apps usually do not add this directly:
[`humation_flutter`](https://pub.dev/packages/humation_flutter) already bundles
it as the default pack.

## Usage

```dart
import 'package:humation/humation.dart';
import 'package:humation_assets_humation_1/humation_assets_humation_1.dart';

final manifest = humation1Manifest; // decoded lazily, cached
final svg = createAvatar(
  manifest,
  const CreateAvatarOptions(seed: 'felix'),
).toSvg();
```

`prewarmHumation1()` forces the one-time decode ahead of first use.

## Contents

- 86 parts across five slots: head (24), body (8), bottom (8), item (43),
  glasses (3).
- Six colour slots: `background`, `stroke`, `hair`, `skin`, `clothes`, `bottom`.

The bundled `humation-1.json` is taken verbatim from
[humation-swift](https://github.com/humation-labs/humation-swift), which
generated it from `@humation/assets-humation-1`. Regenerate the embedded constant
with `node tool/embed.mjs`.

## License

MIT. Artwork is from
[humation-labs/humation](https://github.com/humation-labs/humation) (MIT).
