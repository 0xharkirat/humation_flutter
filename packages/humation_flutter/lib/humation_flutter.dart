/// Deterministic, hand-drawn kawaii avatars for Flutter.
///
/// Render a [HumationAvatar] from a seed and it looks the same every time,
/// drawn natively with a `CustomPainter` (no web view, no network). The core
/// engine and the bundled `humation-1` pack are re-exported for convenience.
///
/// ```dart
/// import 'package:humation_flutter/humation_flutter.dart';
///
/// HumationAvatar(seed: user.id, size: 96);
/// ```
library;

// Core engine API (the core `HumationAvatar` value type is hidden so the widget
// below owns that name).
export 'package:humation/humation.dart' hide HumationAvatar;
export 'package:humation_assets_humation_1/humation_assets_humation_1.dart'
    show humation1Manifest, prewarmHumation1;

export 'src/colors.dart' show humationHex;
export 'src/humation.dart';
export 'src/humation_avatar.dart';
export 'src/image_export.dart';
export 'src/part_preview.dart';
export 'src/slots.dart';
