import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// A 2D affine transform in column-vector convention:
/// `(x, y) -> (a*x + c*y + tx, b*x + d*y + ty)`.
///
/// This mirrors an SVG `matrix(a b c d e f)` (with `tx = e`, `ty = f`) and maps
/// directly onto a Flutter 4x4 [Float64List] for [Path.transform].
class Affine {
  const Affine(this.a, this.b, this.c, this.d, this.tx, this.ty);

  final double a;
  final double b;
  final double c;
  final double d;
  final double tx;
  final double ty;

  static const Affine identity = Affine(1, 0, 0, 1, 0, 0);

  static Affine translate(double tx, double ty) => Affine(1, 0, 0, 1, tx, ty);

  static Affine scale(double sx, double sy) => Affine(sx, 0, 0, sy, 0, 0);

  static Affine rotation(double radians, [double cx = 0, double cy = 0]) {
    final cos = math.cos(radians);
    final sin = math.sin(radians);
    final rot = Affine(cos, sin, -sin, cos, 0, 0);
    if (cx == 0 && cy == 0) return rot;
    return translate(cx, cy).multiply(rot).multiply(translate(-cx, -cy));
  }

  /// `this ∘ other`: the result applies [other] first, then `this`.
  Affine multiply(Affine o) => Affine(
    a * o.a + c * o.b,
    b * o.a + d * o.b,
    a * o.c + c * o.d,
    b * o.c + d * o.d,
    a * o.tx + c * o.ty + tx,
    b * o.tx + d * o.ty + ty,
  );

  /// The uniform scale factor of this transform (`sqrt(|det|)`). Used to scale
  /// stroke width, which SVG scales with the coordinate system.
  double get scaleFactor => math.sqrt((a * d - b * c).abs());

  /// A column-major 4x4 matrix for [Path.transform].
  Float64List toMatrix4() {
    final m = Float64List(16);
    m[0] = a;
    m[1] = b;
    m[5] = d;
    m[4] = c;
    m[10] = 1;
    m[12] = tx;
    m[13] = ty;
    m[15] = 1;
    return m;
  }
}

/// A plain RGBA colour (0..1 per channel). Kept separate from [Color] so the
/// parsed geometry is colour-independent and reusable across recolours.
class Rgba {
  const Rgba(this.r, this.g, this.b, [this.a = 1]);

  final double r;
  final double g;
  final double b;
  final double a;

  static const Rgba black = Rgba(0, 0, 0);
  static const Rgba white = Rgba(1, 1, 1);

  Color toColor() => Color.fromARGB(
    (a * 255).round(),
    (r * 255).round(),
    (g * 255).round(),
    (b * 255).round(),
  );

  /// Parse `#RGB`, `#RRGGBB`, `RGB`, or `RRGGBB`. Returns null otherwise.
  static Rgba? fromHex(String raw) {
    var hex = raw.trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) return null;

    int value;
    switch (hex.length) {
      case 3:
        final r = hex[0], g = hex[1], b = hex[2];
        value = int.parse('$r$r$g$g$b$b', radix: 16);
      case 6:
        value = int.parse(hex, radix: 16);
      default:
        return null;
    }
    return Rgba(
      ((value >> 16) & 0xff) / 255,
      ((value >> 8) & 0xff) / 255,
      (value & 0xff) / 255,
    );
  }
}

/// A paint source for a fill or stroke.
sealed class SvgColor {
  const SvgColor();
}

/// Recolourable: bound to a `var(--hm-<slot>, #fallback)` reference.
class SlotColor extends SvgColor {
  const SlotColor(this.slot, this.fallback);
  final String slot;
  final Rgba fallback;
}

/// A fixed, non-recolourable colour.
class FixedColor extends SvgColor {
  const FixedColor(this.rgba);
  final Rgba rgba;
}

/// No paint (`fill="none"`).
class NoneColor extends SvgColor {
  const NoneColor();
}

/// The resolved paint for one shape. Colours are bindings, not concrete
/// [Color]s, so the same geometry redraws under any palette.
class PaintStyle {
  PaintStyle({
    this.fill = const FixedColor(Rgba.black),
    this.stroke = const NoneColor(),
    this.strokeWidth = 1,
    this.cap = StrokeCap.butt,
    this.join = StrokeJoin.miter,
    this.miterLimit = 4,
    this.fillType = PathFillType.nonZero,
    this.opacity = 1,
  });

  SvgColor fill;
  SvgColor stroke;
  double strokeWidth;
  StrokeCap cap;
  StrokeJoin join;
  double miterLimit;
  PathFillType fillType;
  double opacity;

  PaintStyle copy() => PaintStyle(
    fill: fill,
    stroke: stroke,
    strokeWidth: strokeWidth,
    cap: cap,
    join: join,
    miterLimit: miterLimit,
    fillType: fillType,
    opacity: opacity,
  );
}

/// One drawable shape: a transform-baked [path] plus its [paint] and any active
/// clip path ids (outermost to innermost).
class Shape {
  Shape({required this.path, required this.paint, required this.clipIds});
  final Path path;
  final PaintStyle paint;
  final List<String> clipIds;
}

/// A clip path referenced by `clip-path="url(#id)"`.
class ClipPath {
  ClipPath(this.path);
  final Path path;
}

/// A fully parsed part: ordered shapes plus the clip paths they reference.
class ParsedPart {
  ParsedPart(this.shapes, this.clips);
  final List<Shape> shapes;
  final Map<String, ClipPath> clips;

  static final ParsedPart empty = ParsedPart(const [], const {});
}

/// Parse an SVG `fill`/`stroke` value into a [SvgColor].
SvgColor parseSvgColor(String raw) {
  final value = raw.trim();
  if (value.isEmpty || value.toLowerCase() == 'none') return const NoneColor();

  if (value.startsWith('var(')) return _parseVar(value);

  final rgba = Rgba.fromHex(value);
  if (rgba != null) return FixedColor(rgba);

  final named = _namedColors[value.toLowerCase()];
  if (named != null) return FixedColor(named);

  return const FixedColor(Rgba.black);
}

SvgColor _parseVar(String value) {
  final open = value.indexOf('(');
  final close = value.lastIndexOf(')');
  if (open < 0 || close < 0 || close < open) {
    return const FixedColor(Rgba.black);
  }

  final inner = value.substring(open + 1, close);
  final comma = inner.indexOf(',');
  final name = (comma < 0 ? inner : inner.substring(0, comma)).trim();
  if (!name.startsWith('--hm-')) return const FixedColor(Rgba.black);

  final slot = name.substring('--hm-'.length);
  final fallback = comma < 0
      ? Rgba.black
      : (Rgba.fromHex(inner.substring(comma + 1).trim()) ?? Rgba.black);
  return SlotColor(slot, fallback);
}

const Map<String, Rgba> _namedColors = {
  'ivory': Rgba(1.0, 1.0, 240.0 / 255.0),
  'white': Rgba.white,
  'black': Rgba.black,
};

/// Parse an SVG `transform` attribute (`translate`, `scale`, `rotate`,
/// `matrix`). Functions apply left-to-right to the coordinate system.
Affine parseTransform(String raw) {
  var result = Affine.identity;
  final pattern = RegExp(r'(\w+)\s*\(([^)]*)\)');
  for (final match in pattern.allMatches(raw)) {
    final fn = match.group(1)!;
    final args = match
        .group(2)!
        .split(RegExp(r'[\s,]+'))
        .where((s) => s.isNotEmpty)
        .map((s) => double.tryParse(s) ?? 0)
        .toList();

    final Affine step;
    switch (fn) {
      case 'translate':
        step = Affine.translate(
          args.isNotEmpty ? args[0] : 0,
          args.length > 1 ? args[1] : 0,
        );
      case 'scale':
        final sx = args.isNotEmpty ? args[0] : 1.0;
        step = Affine.scale(sx, args.length > 1 ? args[1] : sx);
      case 'rotate':
        final deg = args.isNotEmpty ? args[0] : 0.0;
        final rad = deg * math.pi / 180;
        step = args.length >= 3
            ? Affine.rotation(rad, args[1], args[2])
            : Affine.rotation(rad);
      case 'matrix':
        step = args.length == 6
            ? Affine(args[0], args[1], args[2], args[3], args[4], args[5])
            : Affine.identity;
      default:
        step = Affine.identity;
    }
    result = result.multiply(step);
  }
  return result;
}
