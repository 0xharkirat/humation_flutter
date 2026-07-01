# Example

Load the bundled `humation-1` manifest and render an avatar with the engine.

```dart
import 'package:humation/humation.dart';
import 'package:humation_assets_humation_1/humation_assets_humation_1.dart';

void main() {
  final manifest = humation1Manifest; // 86 parts, decoded lazily on first use

  final svg = createAvatar(
    manifest,
    const CreateAvatarOptions(seed: 'felix'),
  ).toSvg();

  print(svg.length);
}
```

In a Flutter app you usually do not add this directly:
[`humation_flutter`](https://pub.dev/packages/humation_flutter) already bundles
it as the default pack.
