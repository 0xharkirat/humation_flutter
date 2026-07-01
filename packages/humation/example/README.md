# Example

Generate an avatar as an SVG string. Pure Dart, no Flutter.

```dart
import 'package:humation/humation.dart';
import 'package:humation_assets_humation_1/humation_assets_humation_1.dart';

void main() {
  final svg = createAvatar(
    humation1Manifest,
    const CreateAvatarOptions(seed: 'felix'),
  ).toSvg();

  print(svg); // a self-contained <svg> ... </svg> string
}
```

Add the engine and an artwork pack:

```yaml
dependencies:
  humation: ^0.1.0
  humation_assets_humation_1: ^0.1.0
```

For a Flutter widget instead of an SVG string, use
[`humation_flutter`](https://pub.dev/packages/humation_flutter).
