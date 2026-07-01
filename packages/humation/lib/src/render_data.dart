import 'manifest.dart';

/// Structured render output consumed by native renderers (for example the
/// Flutter `CustomPainter`). Colours stay as slot -> hex here; recolourable
/// regions inside each fragment reference `var(--hm-<slot>, fallback)` and are
/// resolved at paint time, so recolouring never re-parses geometry.
class AvatarRenderData {
  const AvatarRenderData({
    required this.viewBox,
    required this.background,
    required this.colors,
    required this.fragments,
  });

  /// The crop framing the avatar.
  final ViewBox viewBox;

  /// Hex (no `#`) or the literal `transparent`.
  final String background;

  /// colour slot id -> hex (no `#`).
  final Map<String, String> colors;

  /// Layers to draw, already ordered back-to-front by layer slot order.
  final List<RenderFragment> fragments;
}

/// One layer to draw: its inline [svg], the layer [offsetX]/[offsetY], and any
/// part-level [transform] applied on top of the offset.
class RenderFragment {
  const RenderFragment({
    required this.partId,
    required this.selectionSlot,
    required this.layerSlot,
    required this.svg,
    required this.offsetX,
    required this.offsetY,
    this.transform,
  });

  final String partId;
  final String selectionSlot;
  final String layerSlot;

  /// Raw inline SVG fragment (`<svg ...>...</svg>`).
  final String svg;

  /// Layer slot placement in avatar space.
  final double offsetX;
  final double offsetY;

  /// Optional part-level transform (applied after the offset), if the pack sets
  /// one for this fragment.
  final String? transform;
}
