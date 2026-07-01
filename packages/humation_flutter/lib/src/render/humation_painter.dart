import 'package:flutter/rendering.dart';
import 'package:humation/humation.dart';

import '../parsing/geometry.dart';
import 'parsed_part_cache.dart';

/// Paints an [AvatarRenderData] onto a [Canvas].
///
/// Coordinates map straight from SVG space to the canvas (both are y-down). Each
/// fragment is parsed once (cached) into local geometry, then placed by its
/// layer offset and painted with colours resolved from the slot bindings, so
/// recolouring never re-parses.
class HumationPainter extends CustomPainter {
  HumationPainter({required this.data, required this.repaintToken});

  final AvatarRenderData data;

  /// Identity of [data] for repaint decisions (the render data itself has no
  /// value equality). Same token means same avatar.
  final String repaintToken;

  final ParsedPartCache _cache = ParsedPartCache.instance;

  @override
  void paint(Canvas canvas, Size size) {
    final crop = data.viewBox;
    if (crop.width <= 0 || crop.height <= 0) return;

    if (data.background != 'transparent') {
      final rgba = Rgba.fromHex(data.background);
      if (rgba != null) {
        canvas.drawRect(Offset.zero & size, Paint()..color = rgba.toColor());
      }
    }

    // Colour lookup for slot bindings. Includes background so a
    // var(--hm-background) reference resolves too.
    final colors = Map<String, String>.from(data.colors);
    if (data.background != 'transparent') {
      colors['background'] = data.background;
    }

    canvas.save();
    canvas.scale(size.width / crop.width, size.height / crop.height);
    canvas.translate(-crop.x, -crop.y);

    for (final fragment in data.fragments) {
      // The SVG hash disambiguates different packs that reuse the same
      // partId#layerSlot, so a cache hit never returns another pack's geometry.
      final parsed = _cache.get(
        '${fragment.partId}#${fragment.layerSlot}#${fragment.svg.hashCode}',
        fragment.svg,
      );
      canvas.save();
      canvas.translate(fragment.offsetX, fragment.offsetY);
      final transform = fragment.transform;
      if (transform != null) {
        canvas.transform(parseTransform(transform).toMatrix4());
      }
      _drawPart(canvas, parsed, colors);
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawPart(Canvas canvas, ParsedPart part, Map<String, String> colors) {
    for (final shape in part.shapes) {
      canvas.save();
      for (final clipId in shape.clipIds) {
        final clip = part.clips[clipId];
        if (clip != null) canvas.clipPath(clip.path);
      }

      final opacity = shape.paint.opacity.clamp(0.0, 1.0);

      final fill = _resolve(shape.paint.fill, colors);
      if (fill != null) {
        shape.path.fillType = shape.paint.fillType;
        canvas.drawPath(
          shape.path,
          Paint()
            ..style = PaintingStyle.fill
            ..color = _withOpacity(fill, opacity),
        );
      }

      final stroke = _resolve(shape.paint.stroke, colors);
      if (stroke != null && shape.paint.strokeWidth > 0) {
        canvas.drawPath(
          shape.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = shape.paint.strokeWidth
            ..strokeCap = shape.paint.cap
            ..strokeJoin = shape.paint.join
            ..strokeMiterLimit = shape.paint.miterLimit
            ..color = _withOpacity(stroke, opacity),
        );
      }

      canvas.restore();
    }
  }

  Color? _resolve(SvgColor color, Map<String, String> colors) {
    switch (color) {
      case NoneColor():
        return null;
      case FixedColor(:final rgba):
        return rgba.toColor();
      case SlotColor(:final slot, :final fallback):
        final hex = colors[slot];
        final rgba = hex != null ? Rgba.fromHex(hex) : null;
        return (rgba ?? fallback).toColor();
    }
  }

  Color _withOpacity(Color base, double opacity) =>
      opacity >= 1 ? base : base.withValues(alpha: base.a * opacity);

  @override
  bool shouldRepaint(HumationPainter oldDelegate) =>
      oldDelegate.repaintToken != repaintToken;
}
