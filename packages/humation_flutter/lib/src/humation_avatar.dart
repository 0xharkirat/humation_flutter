import 'package:flutter/widgets.dart';
import 'package:humation/humation.dart' as core;
import 'package:humation_assets_humation_1/humation_assets_humation_1.dart';

import 'colors.dart';
import 'render/humation_painter.dart';

/// A deterministic, hand-drawn kawaii avatar.
///
/// Give it a [seed] (typically a user id) and it renders the same avatar every
/// time, natively via a `CustomPainter` (no web view, no network). Override
/// individual [selections] or [colors], or pass a prebuilt [core.AvatarState]
/// with [HumationAvatar.fromState].
///
/// ```dart
/// HumationAvatar(seed: user.id, size: 96)
/// ```
///
/// By default it uses the bundled `humation-1` pack. Pass [manifest] to use a
/// different pack.
class HumationAvatar extends StatelessWidget {
  const HumationAvatar({
    super.key,
    this.seed,
    this.selections,
    this.colors,
    this.background,
    this.crop,
    this.size = 96,
    this.manifest,
  }) : _state = null;

  /// Render an already-resolved [state] directly (no re-resolution).
  const HumationAvatar.fromState(
    core.AvatarState state, {
    super.key,
    this.size = 96,
    this.crop,
    this.manifest,
  }) : _state = state,
       seed = null,
       selections = null,
       colors = null,
       background = null;

  /// Seed string. The same seed always renders the same avatar.
  final String? seed;

  /// Per-slot part overrides (canonical ids, aliases, or slot-scoped names).
  final Map<String, String>? selections;

  /// Per-colour-slot overrides. Each value is a hex `String` (with or without a
  /// leading `#`) or a Flutter [Color], keyed by a slot (see [HumationColorSlot]).
  final Map<String, Object>? colors;

  /// Background: hex, or `'transparent'` (the widget default).
  final String? background;

  /// Optional crop id override.
  final String? crop;

  /// Side length in logical pixels. The avatar is square.
  final double size;

  /// Asset pack to use. Defaults to the bundled `humation-1` pack.
  final core.HumationManifest? manifest;

  final core.AvatarState? _state;

  @override
  Widget build(BuildContext context) {
    final pack = manifest ?? humation1Manifest;
    final state = _state;
    final avatar = state != null
        ? core.HumationAvatar.fromState(
            pack,
            crop != null ? state.copyWith(crop: crop) : state,
          )
        : core.createAvatar(
            pack,
            core.CreateAvatarOptions(
              seed: seed,
              selections: selections,
              colors: humationHexColors(colors),
              background: background ?? 'transparent',
              crop: crop,
            ),
          );

    final data = avatar.toRenderData();

    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        isComplex: true,
        willChange: false,
        painter: HumationPainter(
          data: data,
          repaintToken: _tokenFor(avatar.state, pack),
        ),
      ),
    );
  }
}

String _tokenFor(core.AvatarState state, core.HumationManifest pack) {
  String join(Map<String, String> map) {
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => '${e.key}=${e.value}').join(',');
  }

  // identityHashCode(pack) distinguishes different manifests that could share a
  // template id, so swapping packs live still repaints.
  return '${identityHashCode(pack)}|${state.template}|${join(state.selections)}'
      '|${join(state.colors)}|${state.background}|${state.crop}';
}
