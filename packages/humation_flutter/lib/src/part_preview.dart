import 'package:flutter/widgets.dart';
import 'package:humation/humation.dart' as core;
import 'package:humation_assets_humation_1/humation_assets_humation_1.dart';

import 'colors.dart';
import 'render/humation_painter.dart';

/// A thumbnail of a single [part], framed to its own region rather than the
/// whole avatar. Useful for building a part picker.
///
/// ```dart
/// HumationPartPreview(part: heads.first, colors: state.colors, size: 64)
/// ```
class HumationPartPreview extends StatelessWidget {
  const HumationPartPreview({
    super.key,
    required this.part,
    this.colors,
    this.background = 'transparent',
    this.size = 64,
    this.zoom = 1,
    this.manifest,
  });

  /// The part to preview.
  final core.PartOption part;

  /// Colour overrides, keyed by slot (see [HumationColorSlot]). Each value is a
  /// hex `String` or a Flutter [Color]. Missing slots use the defaults.
  final Map<String, Object>? colors;

  /// Background: hex, or `'transparent'` (the default).
  final String background;

  /// Side length in logical pixels.
  final double size;

  /// Extra magnification. Small parts such as glasses sit in a large frame, so
  /// a builder can zoom them in (the reference uses about 2.15 for glasses).
  final double zoom;

  /// Asset pack. Defaults to the bundled `humation-1` pack.
  final core.HumationManifest? manifest;

  @override
  Widget build(BuildContext context) {
    final pack = manifest ?? humation1Manifest;
    final hex = humationHexColors(colors);
    final data = _previewData(pack, part, colors: hex, background: background);
    return SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: Transform.scale(
          scale: zoom,
          child: CustomPaint(
            size: Size.square(size),
            painter: HumationPainter(
              data: data,
              repaintToken: _token(pack, part, hex, background),
            ),
          ),
        ),
      ),
    );
  }
}

String _token(
  core.HumationManifest pack,
  core.PartOption part,
  Map<String, String>? colors,
  String background,
) {
  final entries = (colors?.entries.toList() ?? [])
    ..sort((a, b) => a.key.compareTo(b.key));
  return '${identityHashCode(pack)}|${part.id}'
      '|${entries.map((e) => '${e.key}=${e.value}').join(',')}|$background';
}

/// Render data for a single part, framed to its first layer's region.
core.AvatarRenderData _previewData(
  core.HumationManifest pack,
  core.PartOption part, {
  Map<String, String>? colors,
  required String background,
}) {
  final resolved = <String, String>{
    for (final slot in pack.colors) slot.id: slot.defaultHex,
    ...?colors,
  };

  final fragments = <core.RenderFragment>[];
  core.ViewBox? viewBox;
  for (final layer in part.layers) {
    final slot = pack.layerSlotById(layer.layerSlot);
    if (layer.svg == null || slot == null) continue;
    viewBox ??= core.ViewBox(
      x: slot.offset.x,
      y: slot.offset.y,
      width: slot.size.width,
      height: slot.size.height,
    );
    fragments.add(
      core.RenderFragment(
        partId: part.id,
        selectionSlot: part.selectionSlot,
        layerSlot: layer.layerSlot,
        svg: layer.svg!,
        offsetX: slot.offset.x,
        offsetY: slot.offset.y,
        transform: layer.transform,
      ),
    );
  }

  // Pad the frame to a centred square so a non-square part (the bundled bottom
  // slot is 80x107) is not distorted when painted into a square canvas.
  final box = viewBox ?? pack.avatarCrop;
  final side = box.width >= box.height ? box.width : box.height;
  final square = core.ViewBox(
    x: box.x - (side - box.width) / 2,
    y: box.y - (side - box.height) / 2,
    width: side,
    height: side,
  );

  return core.AvatarRenderData(
    viewBox: square,
    background: background,
    colors: resolved,
    fragments: fragments,
  );
}
