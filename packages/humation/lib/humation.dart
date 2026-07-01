/// Humation core: a deterministic, hand-drawn kawaii avatar engine.
///
/// Pure Dart, no Flutter and no network. A seed maps to a fixed set of parts via
/// FNV-1a, and the result renders to an SVG string or to structured
/// [AvatarRenderData] a native renderer can paint.
///
/// For a ready-to-use Flutter widget, see the `humation_flutter` package.
library;

export 'src/avatar.dart' show createAvatar, HumationAvatar;
export 'src/engine.dart' show fnv1a, normalizeHex;
export 'src/manifest.dart';
export 'src/render_data.dart' show AvatarRenderData, RenderFragment;
export 'src/resolve.dart'
    show CreateAvatarOptions, AvatarState, resolveAvatarState, resolvePartId;
export 'src/ui_helpers.dart' show getPartsForSlot, getPartsForUiGroup;
export 'src/validator.dart' show validateManifest, ValidationIssue;
