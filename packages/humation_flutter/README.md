# humation_flutter

[![pub package](https://img.shields.io/pub/v/humation_flutter.svg)](https://pub.dev/packages/humation_flutter)

**Deterministic, hand-drawn kawaii avatars for Flutter.**
One seed in, one avatar out, rendered natively with `CustomPainter`. No web view,
no network, no AI. Works on iOS, Android, web, and desktop.

A given seed always renders the same avatar, and it matches the reference
[Humation](https://github.com/humation-labs/humation) web engine, so a user's
avatar looks the same across your web and Flutter apps.

Built on [`humation`](https://pub.dev/packages/humation) (the pure-Dart engine)
and [`humation_assets_humation_1`](https://pub.dev/packages/humation_assets_humation_1)
(the bundled artwork), both re-exported so you usually need only this package.

> **Community port** by [Hark Singh](https://github.com/0xharkirat), not
> affiliated with the Humation Labs team. The engine and artwork are from
> [humation-labs](https://github.com/humation-labs) (MIT).

## Install

```yaml
dependencies:
  humation_flutter: ^0.1.0
```

This bundles the default `humation-1` pack (86 hand-drawn parts), so there is
nothing else to add or download.

## Usage

```dart
import 'package:humation_flutter/humation_flutter.dart';

// Seeded: the same id always renders the same avatar.
HumationAvatar(seed: user.id, size: 96);

// Pick parts and colours. Slots are constants; colours take a Color or hex.
HumationAvatar(
  selections: {HumationSlot.head: 'wavy-medium', HumationSlot.body: 'hoodie'},
  colors: {HumationColorSlot.hair: Colors.brown, HumationColorSlot.skin: '#F4C9A8'},
  size: 96,
);

// Circle crop.
ClipOval(child: HumationAvatar(seed: user.id, size: 40));

// A solid tile behind the avatar (default is transparent).
HumationAvatar(seed: user.id, background: 'F6F5F4', size: 96);
```

### Slots and colours

Five selection slots (`HumationSlot`): `head`, `body`, `bottom`, `item`,
`glasses`. Six colour slots (`HumationColorSlot`): `background`, `stroke`,
`hair`, `skin`, `clothes`, `bottom`.

This is where the Flutter port leans into Flutter's flexibility. Slot names are
string constants, so you get autocomplete and typo-safety, and colours accept a
Flutter `Color` or a hex string. Plain strings still work everywhere
(`{'head': 'wavy-medium'}`, `{'hair': '#4A3728'}`), which is what custom packs
use. The pure-Dart `humation` engine stays string-based for exactly that reason.

List the parts for a slot to build a picker:

```dart
final heads = getPartsForSlot(Humation.manifest, HumationSlot.head);
// heads[0].id, heads[0].name ('wavy-medium'), ...
```

### Saving and restoring

Persist the seed for a seeded avatar, or the `selections` and `colors` for a
custom one:

```dart
final avatar = createAvatar(
  Humation.manifest,
  const CreateAvatarOptions(seed: 'felix'),
);
final json = avatar.toJson(); // {selections, colors, background, crop}

// Later:
HumationAvatar(
  selections: json['selections'].cast<String, String>(),
  colors: json['colors'].cast<String, String>(),
  background: json['background'] as String,
);
```

### Export a PNG

```dart
final Uint8List? png = await Humation.pngForSeed(user.id, pixels: 256);
```

### Prewarm

The bundled pack decodes once, lazily. Move that off the first frame:

```dart
void main() {
  Humation.prewarm();
  runApp(const MyApp());
}
```

### A different pack

`HumationAvatar` takes an optional `manifest`. Pass any `HumationManifest`
(yours, or a served pack) to render custom art. Validate authored packs first
with `validateManifest`.

## How it works

Seed to FNV-1a hash to one part per slot. Each part is a small SVG in a
constrained subset, parsed once to vector paths (cached) and composited with a
`CustomPainter`. Recolouring resolves the six colour slots at paint time, so it
never re-parses. Output is resolution independent: the same widget is crisp at
any size.

## Example

The [example app](example) is a minimal usage demo: a seeded avatar and a
custom selections-and-colours avatar. For a full avatar builder, see
[`playground/`](https://github.com/0xharkirat/humation_flutter/tree/main/playground)
in the repo.

## License

MIT. Artwork and engine design are from
[humation-labs](https://github.com/humation-labs) (MIT).
